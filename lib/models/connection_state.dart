// Connection lifecycle (R6: iOS initiates, host must approve).
enum ConnState {
  disconnected, // idle
  requesting,   // PAIR_REQUEST sent
  waiting,      // awaiting host Accept/Deny
  streaming,    // paired + receiving frames
  denied,       // host pressed Deny / timeout
  error,        // socket / decode error
}

extension ConnStateLabel on ConnState {
  String get label => switch (this) {
        ConnState.disconnected => 'Disconnected',
        ConnState.requesting => 'Requesting…',
        ConnState.waiting => 'Waiting for approval…',
        ConnState.streaming => 'Connected',
        ConnState.denied => 'Denied',
        ConnState.error => 'Error',
      };

  bool get isBusy => this == ConnState.requesting || this == ConnState.waiting;
}
