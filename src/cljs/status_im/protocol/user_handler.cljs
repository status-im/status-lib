(ns status-im.protocol.user-handler
  (:require [status-im.protocol.state.state :as state]))

(defn invoke-user-handler [event-type params]
  ((state/external-handler) (assoc params :event-type event-type)))
