class GameShowPresenter
  PitcherRow = Struct.new(
    :player,
    :today_appearance,
    :today_pitches,
    :last_appearance,
    :last_date,
    :last_pitches,
    :rest_days,
    :eligible_on,
    :eligible_today,
    keyword_init: true
  )

  PitchingAvailabilitySummary = Struct.new(
    :eligible_count,
    :resting_count,
    :next_up_rows,
    keyword_init: true
  )

  NextUpRow = Struct.new(:player_name, :eligible_on, keyword_init: true)

  PitchPlanRow = Struct.new(
    :slot,
    :label,
    :player,
    :player_id,
    :player_name,
    :locked_from_lineup,
    :availability_label,
    :projected_eligible_on,
    :target_pitches,
    keyword_init: true
  )

  attr_reader :game, :opponent_team, :opponent_players

  def initialize(game:, opponent_team: nil, opponent_players: nil)
    @game = game
    @opponent_team = opponent_team
    @opponent_players = opponent_players || []
  end

  def opp_name
    game.opponent_team&.name || game.opponent
  end

  def game_date
    game.date
  end

  def has_lineup?
    game.lineup.present?
  end

  def required_positions
    @required_positions ||= LineupSlot.field_positions.keys - ["extra_hitter"]
  end

  def filled_positions
    return [] unless has_lineup?
    @filled_positions ||= game.lineup.lineup_slots.pluck(:field_position).compact
  end

  def missing_positions
    @missing_positions ||= required_positions - filled_positions
  end

  def starting_pitcher_slot
    return nil unless has_lineup?
    @starting_pitcher_slot ||= game.lineup.lineup_slots.pitcher.first
  end

  def my_pitchers
    @my_pitchers ||= game.team.players.select(&:can_pitch).sort_by { |p| -(p.agg_pitch.to_f) }
  end

  def pitch_appearances_today_by_player_id
    @pitch_appearances_today_by_player_id ||=
      PitchAppearance
        .where(game_id: game.id, player_id: my_pitchers.map(&:id))
        .index_by(&:player_id)
  end

  def last_prior_pitch_appearance_by_player_id
    return @last_prior_pitch_appearance_by_player_id if defined?(@last_prior_pitch_appearance_by_player_id)

    prior =
      PitchAppearance
        .joins(:game)
        .where(player_id: my_pitchers.map(&:id))
        .where("games.date < ?", game_date)
        .where("pitch_appearances.pitches_thrown IS NOT NULL AND pitch_appearances.pitches_thrown > 0")
        .order("games.date DESC")

    by_id = {}
    prior.each { |pa| by_id[pa.player_id] ||= pa }

    @last_prior_pitch_appearance_by_player_id = by_id
  end

  def pitcher_rows
    @pitcher_rows ||=
      my_pitchers.map do |p|
        today = pitch_appearances_today_by_player_id[p.id]
        today_pitches = today&.pitches_thrown.to_i

        gate = p.rest_gate_before_game(game)

        last_date = gate&.last_day
        last_pitches = gate&.day_total.to_i
        eligible_on = gate&.eligible_on
        eligible_today = p.eligible_to_pitch_in_game?(game)

        rest_days =
          if gate.present?
            p.required_rest_days_for_pitches(gate.day_total)
          else
            0
          end

        PitcherRow.new(
          player: p,
          today_appearance: today,
          today_pitches: today_pitches,
          last_appearance: nil,
          last_date: last_date,
          last_pitches: last_pitches,
          rest_days: rest_days,
          eligible_on: eligible_on,
          eligible_today: eligible_today
        )
      end
  end

  def required_rest_days_for(pitches_thrown)
    pitches = pitches_thrown.to_i
    return 0 if pitches <= 20
    return 1 if pitches <= 35
    return 2 if pitches <= 50
    return 3 if pitches <= 65
    4
  end

  def starting_pitcher
    return nil unless has_lineup?
    starting_pitcher_slot&.player
  end

  def starting_pitcher_name
    starting_pitcher&.name
  end

  def plan_player_for(slot)
    return starting_pitcher if slot.starter? && starting_pitcher.present?
    slot.player
  end

  def starter_locked_from_lineup?
    starting_pitcher.present?
  end

  def pitch_plan_slots
    game.ensure_pitch_plan_slots!
    @pitch_plan_slots ||= game.game_pitch_plan_slots.order(:role).includes(:player)
  end

  def eligible_pitchers_for_game
    pitcher_rows.select(&:eligible_today).map(&:player)
  end

  def projected_next_eligible_date(player, target_pitches)
    return nil if player.nil?
    return nil if target_pitches.to_i <= 0

    rest_days = player.required_rest_days_for_pitches(target_pitches)
    game_date + 1 + rest_days
  end

  def missing_positions_human
    missing_positions.map(&:humanize)
  end

  def missing_positions_label
    missing_positions_human.join(", ")
  end

  def pitching_availability_summary
    eligible = pitcher_rows.select(&:eligible_today)
    resting = pitcher_rows.reject(&:eligible_today)
    next_up =
      resting
        .select { |r| r.eligible_on.present? }
        .sort_by(&:eligible_on)
        .first(3)
        .map { |r| NextUpRow.new(player_name: r.player.name, eligible_on: r.eligible_on) }

    PitchingAvailabilitySummary.new(
      eligible_count: eligible.size,
      resting_count: resting.size,
      next_up_rows: next_up
    )
  end

  def eligible_pitcher_ids_for_game
    @eligible_pitcher_ids_for_game ||= pitcher_rows.select(&:eligible_today).map { |r| r.player.id }
  end

  def eligible_pitcher_id_set_for_game
    @eligible_pitcher_id_set_for_game ||= eligible_pitcher_ids_for_game.to_h { |id| [id, true] }
  end

  def pitcher_eligible_today?(player_id)
    return false if player_id.blank?
    eligible_pitcher_id_set_for_game[player_id.to_i] == true
  end

  def pitch_plan_role_label(role)
    case role.to_s
    when "starter" then "Starter"
    when "relief_1" then "Relief 1"
    when "relief_2" then "Relief 2"
    when "relief_3" then "Relief 3"
    when "emergency" then "Emergency"
    else role.to_s.humanize
    end
  end

  def pitch_plan_rows
    eligible_ids = eligible_pitchers_for_game.map(&:id)

    pitch_plan_slots.map do |slot|
      label = pitch_plan_role_label(slot.role)

      player = plan_player_for(slot)
      locked = slot.starter? && starter_locked_from_lineup?

      projected =
        if player && slot.target_pitches.to_i > 0
          projected_next_eligible_date(player, slot.target_pitches)
        end

      availability_label =
        if locked
          "Starter is derived from lineup"
        elsif player.nil?
          "Not assigned"
        elsif eligible_ids.include?(player.id)
          "Available today"
        else
          "Not eligible today"
        end

      PitchPlanRow.new(
        slot: slot,
        label: label,
        player: player,
        player_id: player&.id,
        player_name: player&.name,
        locked_from_lineup: locked,
        availability_label: availability_label,
        projected_eligible_on: projected,
        target_pitches: slot.target_pitches
      )
    end
  end

  PitchPlanRowUI = Struct.new(
    :slot,
    :label,
    :locked_from_lineup,
    :player_id,
    :player_name,
    :availability_label,
    :projected_eligible_on,
    :target_pitches,
    :selected_id,
    :selected_ineligible,
    :wrapper_classes,
    :text_class,
    :select_options,
    keyword_init: true
  )

  def pitch_plan_row_uis
    rows = pitch_plan_rows

    # player_ids already assigned anywhere in the plan
    used_player_ids =
      rows
        .map(&:player_id)
        .compact
        .map(&:to_i)
        .uniq

    rows.map do |row|
      slot = row.slot
      selected_id = slot.player_id&.to_i

      selected_ineligible = selected_id.present? && !pitcher_eligible_today?(selected_id)

      text_class =
        if selected_id.blank?
          "text-stone-700"
        elsif selected_ineligible
          "text-red-700"
        else
          "text-lime-600"
        end

      wrapper_classes =
        if selected_ineligible
          "border border-stone-200 p-3 bg-stone-50 opacity-60"
        else
          "border border-stone-200 p-3"
        end

      select_options =
        my_pitchers.map do |p|
          pid = p.id
          attrs = {}

          # ineligible for this game
          attrs[:disabled] = true unless pitcher_eligible_today?(pid)

          # already used in another slot (but allow current selection)
          if used_player_ids.include?(pid) && pid != selected_id
            attrs[:disabled] = true
          end

          [p.name, pid, attrs]
        end

      PitchPlanRowUI.new(
        slot: slot,
        label: row.label,
        locked_from_lineup: row.locked_from_lineup,
        player_id: row.player_id,
        player_name: row.player_name,
        availability_label: row.availability_label,
        projected_eligible_on: row.projected_eligible_on,
        target_pitches: row.target_pitches,
        selected_id: selected_id,
        selected_ineligible: selected_ineligible,
        wrapper_classes: wrapper_classes,
        text_class: text_class,
        select_options: select_options
      )
    end
  end

  def scouting_report
    @scouting_report ||= ScoutingReportPresenter.new(
      game: game,
      opponent_team: opponent_team,
      opponent_players: opponent_players
    )
  end

  def opponent_team
    @opponent_team ||= game.opponent_team
  end

  def opponent_players
    return [] unless opponent_team.present?
    @opponent_players ||= opponent_team.players.to_a
  end
end
