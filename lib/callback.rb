class Callback
  # define WebSocket callbacks
  def onopen(&blk); @onopen = blk; end
  def onclose(&blk); @onclose = blk; end
  def onerror(&blk); @onerror = blk; end
  def onmessage(&blk); @onmessage = blk; end
  def onping(&blk); @onping = blk; end
  def onpong(&blk); @onpong = blk; end

  def trigger_on_message(ws, msg)
    @onmessage.call(ws, msg) if @onmessage
  end
  def trigger_on_open(ws)
    @onopen.call(ws) if @onopen
  end
  def trigger_on_close(ws)
    @onclose.call(ws) if @onclose
  end
  def trigger_on_ping(ws, data)
    @onping.call(ws, data) if @onping
  end
  def trigger_on_pong(ws, data)
    @onpong.call(ws, data) if @onpong
  end
  def trigger_on_error(ws, reason)
    return false unless @onerror
    @onerror.call(ws, reason)
    true
  end
end
