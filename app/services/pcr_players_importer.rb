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

        was_new ? created += 1 : updated += 1
      end
    end

    { created: created, updated: updated, skipped: skipped }
  end

  private

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