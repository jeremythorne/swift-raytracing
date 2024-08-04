public protocol Texture{
    func value(u: Double, v: Double, p: Vec3) -> Vec3
}

public struct SolidColor : Texture {
    let albedo: Vec3
    init(albedo: Vec3) {
        self.albedo = albedo
    }

    init(red:Double, green: Double, blue: Double) {
        self.init(albedo:Vec3(x: red, y: green, z: blue))
    }

    public func value(u: Double, v: Double, p: Vec3) -> Vec3 {
        return albedo
    }
}