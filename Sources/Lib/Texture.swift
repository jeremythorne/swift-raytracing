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

public struct CheckerTexture : Texture {
    let inv_scale: Double
    let even: Texture
    let odd: Texture

    init(scale:Double, c1: Vec3, c2: Vec3) {
        self.inv_scale = 1.0 / scale
        self.even = SolidColor(albedo: c1)
        self.odd = SolidColor(albedo: c2)
    }

    public func value(u: Double, v: Double, p: Vec3) -> Vec3 {
        let x = Int((inv_scale * p.x).rounded(.down))
        let y = Int((inv_scale * p.y).rounded(.down))
        let z = Int((inv_scale * p.z).rounded(.down))

        let is_even = (x + y + z) % 2 == 0
        return is_even ? even.value(u: u, v: v, p: p) :
            odd.value(u: u, v: v, p: p)
    }
}