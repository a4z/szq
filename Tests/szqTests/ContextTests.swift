import Testing

@testable import szq

@Test func checkDefaultsOnContext() throws {

  let ctx = Context()
  let maxSockets = ctx.maxSockets()
  assert(maxSockets == 1023)

  let ioThreads = ctx.ioThreads()
  assert(ioThreads == 1)

}
