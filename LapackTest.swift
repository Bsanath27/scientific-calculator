import Accelerate

func test() {
    var a: [Double] = [1, 2, 3, 4]
    var pivot = [Int32](repeating: 0, count: 2)
    var error: Int32 = 0
    // Try new API if available?
    // LAPACK.dgetrf is not standard swift.
    // The warning says use -DACCELERATE_NEW_LAPACK.
    // This implies the headers change under the hood.
}
