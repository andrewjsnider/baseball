# app/services/pcr_players_importer.rb
require "csv"

class PcrPlayersImporter
  REQUIRED = ["PCR ID", "First", "Last"].freeze

  def initialize(path:)
    @path = path
  end

  def import!
    lines = File.readlines(@path, encoding: "bom|utf-8")
    raise "Empty file" if lines.empty?

    header_index, col_sep = find_header(lines)
    raise "Could not find header row containing: #{REQUIRED.join(', ')}" unless header_index

    csv_text = lines[header_index..].join
    csv = CSV.parse(csv_text, headers: true, col_sep: col_sep)

    created = 0
    updated = 0
    skipped = 0

    Player.transaction do
      csv.each do |row|
        pcr_id = row["PCR ID"].to_s.strip
        if pcr_id.blank?
          skipped += 1
          next
        end

        player = Player.find_or_initialize_by(pcr_id: pcr_id)
        was_new = player.new_record?

        first = row["First"].to_s.strip
        last  = row["Last"].to_s.strip

        player.first_name = first.presence
        player.last_name  = last.presence
        player.name       = [first, last].reject(&:blank?).join(" ").presence || player.name

        player.pcr_hitting  = dec_or_nil(row["Hitting"])
        player.pcr_fielding = dec_or_nil(row["Fielding"])
        player.pcr_throwing = dec_or_nil(row["Throwing"])
        player.pcr_pitching = dec_or_nil(row["Pitching"])
        player.pcr_total    = dec_or_nil(row["TOTAL"])

        age = age_from_pcr_id(pcr_id)
        player.age = age if age.present? && player.age.blank?

        notes = row["NOTES"].to_s.strip
        if notes.present?
          secs = secs_from_notes(notes)
          player.speed = speed_rating_from_secs(secs) if secs.present?

          player.notes = notes
        end

        player.save!

        player.player_positions.joins(:position)
              .where(positions: { name: ["P", "C", "SS", "OF"] })
              .destroy_all

        assign_positions_from_row!(player, row)

        was_new ? created += 1 : updated += 1
      end
    end

    { created: created, updated: updated, skipped: skipped }
  end

  private

  def assign_positions_from_row!(player, row)
    add_position!(player, "P") if dec_or_nil(row["Pitching"]).present?

    fielding = dec_or_nil(row["Fielding"])
    if fielding.present?
      if fielding >= 4.0
        add_position!(player, "SS")
      elsif fielding <= 3.0
        add_position!(player, "OF")
      end
    end
  end

  def add_position!(player, pos_name)
    position = Position.find_by(name: pos_name) || Position.create!(name: pos_name)
    return if player.positions.exists?(id: position.id)

    player.positions << position
  end

  def find_header(lines)
    lines.first(30).each_with_index do |line, idx|
      cols, sep = parse_header_cols(line)
      normalized = cols.map { |c| c.to_s.strip }
      return [idx, sep] if REQUIRED.all? { |h| normalized.include?(h) }
    end
    nil
  end

  def parse_header_cols(line)
    # Prefer tab if it looks tab-delimited
    if line.include?("\t")
      cols = line.strip.split("\t")
      return [cols, "\t"]
    end

    # Otherwise try standard CSV commas
    cols = CSV.parse_line(line)
    cols ||= []
    [cols, ","]
  end

  def dec_or_nil(value)
    s = value.to_s.strip
    return nil if s.blank?
    Float(s)
  rescue ArgumentError
    nil
  end

  def secs_from_notes(notes)
    m = notes.match(/(\d+(?:\.\d+)?)\s*secs?\b/i)
    return nil unless m
    m[1].to_f
  end

  # Map 30-yard dash time (seconds) to 1..5 speed grade.
  def speed_rating_from_secs(secs)
    return nil unless secs.present?

    return 5 if secs <= 3.40
    return 4 if secs <= 3.60
    return 3 if secs <= 3.90
    return 2 if secs <= 4.20
    1
  end

  def age_from_pcr_id(pcr_id)
    return nil if pcr_id.blank?
    m = pcr_id.strip.match(/\A(?:W)?(\d{2})-/)
    m ? m[1] : nil
  end
end