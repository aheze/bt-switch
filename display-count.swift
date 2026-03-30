import CoreGraphics
var count: UInt32 = 0
CGGetActiveDisplayList(0, nil, &count)
print(count)
