import Foundation // for tan()

public struct Vec3 : Equatable {
    public let x: Double
    public let y: Double
    public let z: Double

    public init(x: Double, y: Double, z:Double) {
        self.x = x
        self.y = y
        self.z = z}

    public func dot(_ b: Vec3) -> Double {
        return x * b.x + y * b.y + z * b.z
    }

    public func length_squared() -> Double {
        return dot(self)
    }

    public func length() -> Double {
        return length_squared().squareRoot()
    }

    public func normalize() -> Vec3 {
        let l = length()
        return Vec3(x:x / l, y: y / l, z: z / l)    
    }

    public func cross(_ b: Vec3) -> Vec3 {
        return Vec3(
            x: y * b.z - z * b.y,
            y: z * b.x - x * b.z,
            z: x * b.y - y * b.x
        )
    }

    public func clamp(vmin: Vec3, vmax: Vec3) -> Vec3 {
        return Vec3(
            x: max(vmin.x, min(vmax.x, x)),
            y: max(vmin.y, min(vmax.y, y)),
            z: max(vmin.z, min(vmax.z, z)))
    }

    static public func random(in range: ClosedRange<Double>) -> Vec3 {
        let lower = range.lowerBound
        let upper = range.upperBound
        let frange = lower...upper
        return Vec3(
            x:Double.random(in: frange),
            y:Double.random(in: frange),
            z:Double.random(in: frange)
        )
    }

    public subscript(index: Int) -> Double {
        if index == 2 { return z }
        if index == 1 { return y }
        return x
    }

    static public let zero = Vec3(x: 0.0, y: 0.0, z: 0.0)
    static public let one = Vec3(x: 1.0, y: 1.0, z: 1.0)
}

prefix public func - (a:Vec3) -> Vec3 {
    return Vec3(x:-a.x, y:-a.y, z:-a.z)
}

public func + (left: Vec3, right: Vec3) -> Vec3 {
    return Vec3(
        x: left.x + right.x,
        y: left.y + right.y,
        z: left.z + right.z
    )
}

public func * (left: Vec3, right: Vec3) -> Vec3 {
    return Vec3(
        x: left.x * right.x,
        y: left.y * right.y,
        z: left.z * right.z
    )
}

public func - (left: Vec3, right: Vec3) -> Vec3 {
    return Vec3(
        x: left.x - right.x,
        y: left.y - right.y,
        z: left.z - right.z
    )
}

public func * (left: Double, right: Vec3) -> Vec3 {
    return Vec3(
        x: left * right.x,
        y: left * right.y,
        z: left * right.z
    )
}

public func * (left: Vec3, right: Double) -> Vec3 {
    return Vec3(
        x: right * left.x,
        y: right * left.y,
        z: right * left.z
    )
}

public func / (left: Vec3, right: Double) -> Vec3 {
    return Vec3(
        x: left.x / right,
        y: left.y / right,
        z: left.z / right
    )
}
