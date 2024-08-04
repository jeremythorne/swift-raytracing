import Foundation // for tan()

struct Image {
    let width: Int
    let height: Int
    var data: [UInt8]
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        data = Array(repeating: UInt8(0), count: width * height * 3)
    }

    mutating func set_pixel(x: Int, y: Int, val: (UInt8, UInt8, UInt8)) {
        let index = (x + y * width) * 3
        data[index] = val.2
        data[index + 1] = val.1
        data[index + 2] = val.0
    }

    func write(file: String)  {
        let header: [UInt8] = [
           0,
           0,
           2,                   /* uncompressed RGB */
           0,0,
           0,0,
           0,
           0,0,           /* X origin */
           0,0,           /* y origin */
           UInt8(width & 0x00FF),
           UInt8((width & 0xFF00) / 256),
           UInt8(height & 0x00FF),
           UInt8((height & 0xFF00) / 256),
           24,                        /* 24 bit bitmap */
           0]
        var d = Data(header)
        d.append(contentsOf:data)
        try! d.write(to: URL(string: "file://\(file)")!)
    }
}
