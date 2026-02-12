module ApplicationHelper
  def tier_badge_class(tier)
    base = "px-2 py-1 text-xs font-semibold"

    if tier == "A"
      "#{base} bg-green-200 text-green-900"
    elsif tier == "B"
      "#{base} bg-blue-200 text-blue-900"
    elsif tier == "C"
      "#{base} bg-yellow-200 text-yellow-900"
    else
      "#{base} bg-stone-200 text-stone-800"
    end
  end
end
