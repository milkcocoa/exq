defmodule Exq.Enqueuer.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: supervisor_name(opts[:name]))
  end

  def init(opts) do
   redis = opts[:redis] || Exq.Opts.redis_client_name(opts[:name])
   opts = Keyword.merge(opts, [redis: redis, start_by_enqueuer_sup: true])
   redis_worker =
     case Process.whereis(redis) do
       nil ->
         {redix_opts, connection_opts} = Exq.Opts.redis_opts(opts)
         [worker(Redix, [redix_opts, connection_opts])]
       _ -> []
     end
   children = [
     worker(Exq.Enqueuer.Server, [opts]),
     ]
   redis_worker ++ children
   |> supervise(strategy: :one_for_one, max_restarts: 20)
  end

  def supervisor_name(nil), do: Exq.Enqueuer.Sup
  def supervisor_name(name), do: "#{name}.Sup" |> String.to_atom

end
