import json, json_serialization, strutils
import signals/[base, chronicles_logs, community, discovery_summary, envelope, expired, mailserver, messages, signal_type, stats, wallet, whisper_filter]

export base, chronicles_logs, community, discovery_summary, envelope, expired, mailserver, messages, signal_type, stats, wallet, whisper_filter

proc decode*(jsonSignal: JsonNode): Signal =
  let signalString = jsonSignal{"type"}.getStr
  var signalType: SignalType
  try:
    signalType = parseEnum[SignalType](signalString)
  except:
    raise newException(ValueError, "Unknown signal received: " & signalString)

  result = case signalType:
    of SignalType.Message: MessageSignal.fromEvent(jsonSignal)
    of SignalType.EnvelopeSent: EnvelopeSentSignal.fromEvent(jsonSignal)
    of SignalType.EnvelopeExpired: EnvelopeExpiredSignal.fromEvent(jsonSignal)
    of SignalType.WhisperFilterAdded: WhisperFilterSignal.fromEvent(jsonSignal)
    of SignalType.Wallet: WalletSignal.fromEvent(jsonSignal)
    of SignalType.NodeLogin: Json.decode($jsonSignal, NodeSignal)
    of SignalType.DiscoverySummary: DiscoverySummarySignal.fromEvent(jsonSignal)
    of SignalType.MailserverRequestCompleted: MailserverRequestCompletedSignal.fromEvent(jsonSignal)
    of SignalType.MailserverRequestExpired: MailserverRequestExpiredSignal.fromEvent(jsonSignal)
    of SignalType.CommunityFound: CommunitySignal.fromEvent(jsonSignal)
    of SignalType.Stats: StatsSignal.fromEvent(jsonSignal)
    of SignalType.ChroniclesLogs: ChroniclesLogsSignal.fromEvent(jsonSignal)
    of SignalType.HistoryRequestCompleted: HistoryRequestCompletedSignal.fromEvent(jsonSignal)
    of SignalType.HistoryRequestStarted: HistoryRequestStartedSignal.fromEvent(jsonSignal)
    of SignalType.HistoryRequestFailed: HistoryRequestFailedSignal.fromEvent(jsonSignal)
    else: Signal()
  
  result.signalType = signalType
