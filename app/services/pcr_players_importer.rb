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

        player.pcr_hitting  = int_or_nil(row["Hitting"])
        player.pcr_fielding = int_or_nil(row["Fielding"])
        player.pcr_throwing = int_or_nil(row["Throwing"])
        player.pcr_pitching = int_or_nil(row["Pitching"])
        player.pcr_total    = int_or_nil(row["TOTAL"])

        age = age_from_pcr_id(pcr_id)
        player.age = age if age.present? && player.age.blank?

        notes = row["NOTES"].to_s.strip
        player.notes = notes.presence if notes.present?

        player.save!

        player.positions.where(name: ["P", "C", "SS", "2B", "OF"]).destroy_all
        assign_positions_from_row!(player, row)

        was_new ? created += 1 : updated += 1
      end
    end

    { created: created, updated: updated, skipped: skipped }
  end

  private

  def assign_positions_from_row!(player, row)
    # Pitcher if they have pitching data
    if int_or_nil(row["Pitching"]).present?
      add_position!(player, "P")
    end

    # Catcher if they have catching data (expects a "Catching" column)
    if int_or_nil(row["Catching"]).present?
      add_position!(player, "C")
    end

    # Middle INF if they have INF 4+ (expects an "INF" column)
    fielding = int_or_nil(row["Fielding"])
    if fielding.present?
      if fielding >= 4
        add_position!(player, "SS")
        add_position!(player, "2B")
      elsif fielding <= 3
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

  def int_or_nil(value)
    s = value.to_s.strip
    return nil if s.blank?
    Integer(s)
  rescue ArgumentError
    nil
  end

  def age_from_pcr_id(pcr_id)
    return nil if pcr_id.blank?
    m = pcr_id.strip.match(/\A(?:W)?(\d{2})-/)
    m ? m[1] : nil
  end
end