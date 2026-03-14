defmodule Horde.UniformDistribution do
  @behaviour Horde.DistributionStrategy

  @moduledoc """
  Distributes processes to nodes uniformly using a hash ring.

  Given the *same* set of members, it will always start
  the same process on the same node.
  """

  def choose_node(child_spec, members) do
    identifier = :erlang.phash2(child_spec.id)

    members
    |> Enum.filter(&match?(%{status: :alive}, &1))
    |> Map.new(fn member ->
      {_name, node} = member.name
      {node, member}
    end)
    |> case do
      members when map_size(members) == 0 ->
        {:error, :no_alive_nodes}

      members ->
        nodes = Map.keys(members)

        chosen_member =
          HashRing.new()
          |> HashRing.add_nodes(nodes)
          |> HashRing.key_to_node(identifier)

        {:ok, Map.get(members, chosen_member)}
    end
  end

  def has_quorum?(_members), do: true
end
