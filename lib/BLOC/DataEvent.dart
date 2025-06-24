


// events represent the inputs or actions that the Bloc responds to.
// equatable provides value equality.
abstract class DataEvent{
  // a data event is an action that triggers a change in state.
  // an event represents everything that happens inside a bloc (processing of data).
  const DataEvent();
}

class FetchData extends DataEvent{
  final String? parameter;
  final String? userId;
  FetchData(this.parameter, this.userId);
}