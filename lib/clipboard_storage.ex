defmodule MavuSnippetsUi.ClipboardStorage do
  @moduledoc false

  def process_storage_cmd(:put, clist, conf) when is_list(clist) do
    MavuBuckets.set_value(conf[:bucketkey], "items", clist)
  end

  def process_storage_cmd(:get, _msg, conf) do
    MavuBuckets.get_value(conf[:bucketkey], "items")
  end

  def process_storage_cmd(cmd, _msg, _conf) do
    raise "unknown clipboard command: #{cmd}"
  end

  def create(bucketkey) when is_binary(bucketkey) do
    conf = [bucketkey: bucketkey]
    # conf |> IO.inspect(label: "mwuits-debug 2021-03-11_12:49 create clipbaord")
    &process_storage_cmd(&1, &2, conf)
  end
end
