defmodule AeCanary.Statistics.InterquartileRange do

  def iqr(list), do: Statistics.iqr(list)

  def third_quartile(list), do: Statistics.quartile(list, :third)

  def q3_fence(q3, iqr, multiplier) do
    boundary = iqr * multiplier
    q3 + boundary
  end
end
