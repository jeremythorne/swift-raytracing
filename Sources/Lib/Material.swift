import Foundation // for tan()

public protocol Material {
    func scatter(r: Ray, rec: HitRecord) -> AttenuatedRay?   
}

public struct Lambertian : Material {
    let albedo:Vec3
    public init(albedo:Vec3) {
        self.albedo = albedo
    }
    public func scatter(r: Ray, rec: HitRecord) -> AttenuatedRay? {
        var scatter_direction = rec.normal + random_unit_vector()

        if near_zero(v: scatter_direction) {
            scatter_direction = rec.normal;
        }

        return AttenuatedRay(
            attenuation: albedo,
            ray: Ray(a: rec.p, b: scatter_direction, tm: r.time())
        )
    } 
    
}

struct Metal : Material { 
    let albedo: Vec3
    let fuzz: Double

    public func scatter(r: Ray, rec: HitRecord) -> AttenuatedRay? {
        let reflected = reflect(r.direction().normalize(), rec.normal) +
                fuzz * random_in_unit_sphere()

        if reflected.dot(rec.normal) < 0.0 {
            return nil
        } else {
            return AttenuatedRay(
                attenuation: albedo,
                ray: Ray(a:rec.p, b:reflected, tm: r.time())
            )
        }
    }
}

struct Dialectric: Material {
    let ir: Double

    func reflectance(_ cosine:Double, _ ref_idx:Double) -> Double {
        // Schlick's approximation
        let r0 = (1.0 - ref_idx) / (1.0 + ref_idx)
        let r02 = r0 * r0
        return r02 + (1.0 - r0) * pow(1.0 - cosine, 5)
    }

    public func scatter(r: Ray, rec: HitRecord) -> AttenuatedRay? {
        let refraction_ratio = if rec.front_face { 1.0/self.ir } else { self.ir }
        let unit_direction = r.direction().normalize()

        let cos_theta = min(-unit_direction.dot(rec.normal), 1.0)
        let sin_theta = (1.0 - cos_theta * cos_theta).squareRoot()

        let cannot_refract = sin_theta * refraction_ratio > 1.0
        let direction = if cannot_refract ||
                reflectance(cos_theta, refraction_ratio) > Double.random(in: 0...1.0) {
            reflect(unit_direction, rec.normal)
        } else {
            refract(unit_direction, rec.normal, refraction_ratio)
        }
        return AttenuatedRay(
            attenuation: Vec3(x: 1.0, y: 1.0, z: 1.0),
            ray: Ray(a: rec.p, b: direction, tm: r.time())
        )
    }
}

