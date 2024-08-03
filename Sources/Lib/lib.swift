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

public struct Vec3 : Equatable {
    public let x: Float
    public let y: Float
    public let z: Float

    public init(x: Float, y: Float, z:Float) {
        self.x = x
        self.y = y
        self.z = z}

    public func dot(_ b: Vec3) -> Float {
        return x * b.x + y * b.y + z * b.z
    }

    public func length_squared() -> Float {
        return dot(self)
    }

    public func length() -> Float {
        return length_squared().squareRoot()
    }

    public func normalize() -> Vec3 {
        let l = length()
        return Vec3(x:x/l, y: y/l, z: z/l)    
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
        let lower = Float(range.lowerBound)
        let upper = Float(range.upperBound)
        let frange = lower...upper
        return Vec3(
            x:Float.random(in: frange),
            y:Float.random(in: frange),
            z:Float.random(in: frange)
        )
    }

    public subscript(index: Int) -> Float {
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

public func * (left: Float, right: Vec3) -> Vec3 {
    return Vec3(
        x: left * right.x,
        y: left * right.y,
        z: left * right.z
    )
}

public func * (left: Vec3, right: Float) -> Vec3 {
    return Vec3(
        x: right * left.x,
        y: right * left.y,
        z: right * left.z
    )
}

public func / (left: Vec3, right: Float) -> Vec3 {
    return Vec3(
        x: left.x / right,
        y: left.y / right,
        z: left.z / right
    )
}

public struct Ray {
    let a: Vec3
    let b: Vec3
    let tm: Float

    public init(a: Vec3, b: Vec3) {
        self.a = a
        self.b = b
        tm = 0.0
    }

    init(a: Vec3, b: Vec3, tm: Float) {
        self.a = a
        self.b = b
        self.tm = tm
    }

    func origin() -> Vec3 {
        return a
    }

    func direction() -> Vec3 {
        return b
    }

    func time() -> Float {
        return tm
    }

    func point_at_parameter(t: Float) -> Vec3 {
        return a + t * b
    }
}

public struct AttenuatedRay {
    let attenuation: Vec3
    let ray: Ray
}

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
    let fuzz: Float

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
    let ir: Float

    func reflectance(_ cosine:Float, _ ref_idx:Float) -> Float {
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
                reflectance(cos_theta, refraction_ratio) > Float.random(in: 0...1.0) {
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

public struct HitRecord {
    public let t: Float
    public let p: Vec3
    public let front_face: Bool
    public let normal: Vec3
    public let material: Material

    init(t: Float, p: Vec3, r: Ray, outward_normal: Vec3,
            material: Material) {
        let (front_face, normal) = HitRecord.face_normal(r, outward_normal) 
        self.t = t
        self.p = p
        self.front_face = front_face
        self.normal = normal
        self.material = material
    }

    static func face_normal(_ r: Ray, _ outward_normal: Vec3) -> (Bool, Vec3) {
        let front_face = r.direction().dot(outward_normal) < 0.0
        let normal = if front_face { outward_normal } else { -outward_normal }
        return (front_face, normal)
    }

}

public struct Interval : Equatable {
    public let t_min:Float
    public let t_max:Float

    public init() {
        t_min = 0.0
        t_max = 0.0
    }

    public init(t_min: Float, t_max:Float) {
        self.t_min = t_min
        self.t_max = t_max
    }

    public init(a:Interval, b:Interval) {
        // create the interval tightly enclosing the two input intervals
        t_min = a.t_min <= b.t_min ? a.t_min : b.t_min
        t_max = a.t_max >= b.t_max ? a.t_max : b.t_max
    }

    public func expand(delta:Float) -> Interval {
        let padding = delta/2.0
        return Interval(t_min:t_min - padding, t_max:t_max + padding)
    }

    public func size() -> Float {
        return t_max - t_min
    }

    static let empty = Interval(t_min: Float.infinity, t_max: -1.0 * Float.infinity)
}

public protocol Hitable {
    func hit(r: Ray, ray_t:Interval) -> HitRecord?
    func bounding_box() -> AABB
}


public struct AABB : Equatable {
    public let x:Interval
    public let y:Interval
    public let z:Interval

    public init() { 
        x = Interval.empty
        y = Interval.empty
        z = Interval.empty
    }

    public init(a:Vec3, b:Vec3) {
        x = a.x <= b.x ? Interval(t_min:a.x, t_max:b.x) : Interval(t_min:b.x, t_max:a.x) 
        y = a.y <= b.y ? Interval(t_min:a.y, t_max:b.y) : Interval(t_min:b.y, t_max:a.y) 
        z = a.z <= b.z ? Interval(t_min:a.z, t_max:b.z) : Interval(t_min:b.z, t_max:a.z) 
    }

    public init(box0:AABB, box1:AABB) {
        x = Interval(a: box0.x, b: box1.x)
        y = Interval(a: box0.y, b: box1.y)
        z = Interval(a: box0.z, b: box1.z)
    }

    func axis_interval(n: Int) -> Interval {
        if n == 1 { return y }
        if n == 2 { return z }
        return x
    }
    
    public func hit(r: Ray, ray_t:Interval) -> Bool {
        var t = ray_t
        let ray_orig = r.origin()
        let ray_dir = r.direction()
        for axis in 0..<3 {
            let ax = axis_interval(n:axis)
            let adinv = 1.0 / ray_dir[axis]
            let t0 = (ax.t_min - ray_orig[axis]) * adinv
            let t1 = (ax.t_max - ray_orig[axis]) * adinv
            if t0 < t1 {
                if t0 > t.t_min { t = Interval(t_min:t0, t_max:t.t_max) }
                if t1 < t.t_max { t = Interval(t_min:t.t_min, t_max:t1) }
            } else {
                if t1 > t.t_min { t = Interval(t_min:t1, t_max:t.t_max) }
                if t0 < t.t_max { t = Interval(t_min:t.t_min, t_max:t0) }
            }
            if t.t_max <= t.t_min {
                return false
            }
        }
        return true
    }

    public func longest_axis() -> Int {
        if x.size() > y.size() {
            return x.size() > z.size() ? 0 : 2
        } else {
            return y.size() > z.size() ? 1 : 2
        }
    }
    static public let empty = AABB()
}

public struct Sphere : Hitable {
    let center1: Vec3
    let radius: Float
    let material: Material
    let center_vec: Vec3
    let is_moving: Bool
    let bbox: AABB

    public init(center: Vec3, radius: Float, material: Material) {
        self.center1 = center
        self.radius = max(0.0, radius)
        self.material = material
        is_moving = false
        center_vec = Vec3.zero
        let rvec = Vec3(x:radius, y: radius, z:radius)
        bbox = AABB(a:center1 - rvec, b: center1 + rvec)
    }

    init(center1: Vec3, center2: Vec3, radius: Float, material: Material) {
        self.center1 = center1
        self.radius = radius
        self.material = material
        is_moving = true
        center_vec = center2 - center1
        let rvec = Vec3(x:radius, y: radius, z:radius)
        let box1 = AABB(a:center1 - rvec, b:center1 + rvec)
        let box2 = AABB(a:center2 - rvec, b:center2 + rvec)
        bbox = AABB(box0:box1, box1:box2)
     }

    public func hit(r: Ray, ray_t:Interval) -> HitRecord? {
        let center = is_moving ? sphere_center(time:r.time()) :  center1
        let oc = r.origin() - center
        let a = r.direction().dot(r.direction())
        let b = 2.0 * oc.dot(r.direction())
        let c = oc.dot(oc) - self.radius * self.radius
        let discriminant = b * b - 4.0 * a * c
        if discriminant > 0.0 {
            let choices = [
                (-b - discriminant.squareRoot()) / (2.0 * a),
                (-b + discriminant.squareRoot()) / (2.0 * a)]
            for temp in choices {
                if temp < ray_t.t_max && temp > ray_t.t_min {
                    let p = r.point_at_parameter(t: temp)
                    return HitRecord(
                        t: temp, p: p, r: r,
                        outward_normal: (p - center) / radius,
                        material: material)
                }
            }
        }
        return nil
    }

    public func bounding_box() -> AABB {
        return bbox
    }

    func sphere_center(time: Float) -> Vec3 {
        center1 + time * center_vec
    }
}

public struct HitableList: Hitable {
    var list: [Hitable]
    var bbox: AABB

    init(list:[Hitable]) {
        self.list = list
        self.bbox = AABB()
        for object in list {
            bbox = AABB(box0:bbox, box1: object.bounding_box())
        }
    }

    public func hit(r: Ray, ray_t:Interval) -> HitRecord? {
        var rec:HitRecord? = nil
        var closest_so_far = ray_t.t_max
        for hitable in list {
            if let temp_rec = hitable.hit(r:r,
                        ray_t:Interval(t_min:ray_t.t_min, t_max:closest_so_far)) {
                closest_so_far = temp_rec.t
                rec = temp_rec
            }     
        }
        return rec
    }

    public func bounding_box() -> AABB {
        return bbox
    }
}

func box_compare(a: Hitable, b:Hitable, axis: Int) -> Bool {
    let a_axis_interval = a.bounding_box().axis_interval(n:axis)
    let b_axis_interval = b.bounding_box().axis_interval(n:axis)
    return a_axis_interval.t_min < b_axis_interval.t_min
}

func make_box_compare(axis:Int) -> (Hitable, Hitable) -> Bool {
    func compare(a: Hitable, b: Hitable) -> Bool {
        return box_compare(a:a, b:b, axis:axis)
    }
    return compare
}

// needs to be a class as self referential
public class BVHNode: Hitable {
    let left:Hitable
    let right:Hitable
    let bbox:AABB

    public convenience init(list:HitableList) {
        self.init(list:list.list[...])
    }

    public init(list:ArraySlice<any Hitable>) {
        var box = AABB.empty
        for item in list {
            box = AABB(box0: box, box1: item.bounding_box())
        }
        bbox = box
        let axis = bbox.longest_axis()
        let comparator = make_box_compare(axis:axis)

        switch list.count {
        case 1:
            left = list[list.startIndex]
            right = list[list.startIndex]
        case 2:
            left = list[list.startIndex]
            right = list[list.startIndex + 1]
        default:
            let sorted = list.sorted(by: comparator)
            let mid = sorted.startIndex + sorted.count / 2
            left = BVHNode(list:sorted[..<mid])
            right = BVHNode(list:sorted[mid...])
        }
    }

    public func hit(r: Ray, ray_t: Interval) -> HitRecord? {
        if !bbox.hit(r:r, ray_t:ray_t) {
            return nil
        }
        let hit_left = left.hit(r:r, ray_t: ray_t)
        let hit_right = right.hit(r:r, ray_t: Interval(t_min:ray_t.t_min, t_max:
            hit_left?.t ?? ray_t.t_max))
        if hit_right == nil {
            return hit_left
        } else if hit_left == nil {
            return hit_right
        }
        return hit_left!.t < hit_right!.t ? hit_left : hit_right
    }

    public func bounding_box() -> AABB {
        return bbox
    }
}

struct Camera {
    let origin: Vec3
    let lower_left_corner: Vec3
    let horizontal: Vec3
    let vertical: Vec3
    let u: Vec3
    let v: Vec3
    let w: Vec3
    let lens_radius: Float

    init(look_from:Vec3,
            look_at:Vec3,
            vup:Vec3,
            fov:Float, 
            aspect_ratio:Float,
            aperture:Float,
            focus_dist:Float
            ) {
        let theta = fov * Float.pi / 180.0
        let h = tan(theta / 2.0)
        let viewport_height = 2.0 * h
        let viewport_width = aspect_ratio * viewport_height

        self.w = (look_from - look_at).normalize()
        self.u = vup.cross(w).normalize()
        self.v = w.cross(u)

        self.lens_radius = aperture / 2.0

        self.origin = look_from
        self.horizontal = focus_dist * viewport_width * u
        self.vertical = focus_dist * viewport_height * v
        self.lower_left_corner = origin - 0.5 * (horizontal + vertical) - focus_dist * w
    }

    func get_ray(s:Float, t:Float) -> Ray {
        let rd = random_in_unit_disk() * lens_radius 
        let offset = u * rd.x + v * rd.y
        let ray_time = Float.random(in: 0.0...1.0)
        return Ray( a: origin + offset,
                    b: lower_left_corner +
                        s * horizontal +
                        t * vertical -
                        origin -
                        offset,
                    tm: ray_time)
    }
}

func random_in_unit_sphere() -> Vec3 {
    while true {
        let p = Vec3.random(in: -1.0...1.0)
        if p.length_squared() <= 1.0 {
            return p
        }
    }
}

func random_unit_vector() -> Vec3 {
    return random_in_unit_sphere().normalize()
}

func random_in_unit_disk() -> Vec3 {
    while true {
        var p = Vec3.random(in: -1.0...1.0)
        p = Vec3(x:p.x, y: p.y, z: 0.0)
        if p.length_squared() <= 1.0 {
            return p;
        }
    }
}

func near_zero(v: Vec3) -> Bool {
    let e:Float = 1e-8
    return abs(v.x) < e && abs(v.y) < e && abs(v.z) < e
}

func reflect(_ a: Vec3, _ b:Vec3) -> Vec3 {
    a - 2.0 * a.dot(b) * b
}

func refract(_ uv: Vec3, _ n: Vec3, _ etai_over_etat: Float) -> Vec3 {
    let cos_theta = min((-uv).dot(n), 1.0)
    let r_out_perp = etai_over_etat * (uv + cos_theta * n)
    let r_out_parallel = -abs(1.0 - r_out_perp.length_squared()).squareRoot() * n
    return r_out_perp + r_out_parallel
}

func debug_mirror_scene() -> HitableList {
    var list = [Hitable]()
    list.append(Sphere(center:Vec3(x:0, y:0, z:0), radius: 1.0,
            material: Metal(albedo: Vec3(x: 1, y: 1, z: 1), fuzz: 0.0)))
    return HitableList(list:list)
}

func debug_white_sphere_scene() -> HitableList {
    var list = [Hitable]()
    list.append(Sphere(center:Vec3(x:0, y:0, z:0), radius: 1.0,
            material: Lambertian(albedo: Vec3(x: 1, y: 0, z: 0))))
    return HitableList(list:list)
}

func debug_simple_sphere_scene() -> HitableList {
    var list = [Hitable]()
    let s = 3
    let o = -6
    for x in 0..<5 {
        for y in 0..<5 {
            for z in 0..<5 {
                let s = Sphere(center:Vec3(
                    x: Float(x * s + o), 
                    y: Float(y * s + o), 
                    z: Float(z * s + o)), 
                radius: 1, material: Lambertian(albedo: Vec3(
                    x: Float(x) / 4,
                    y: Float(y) / 4, 
                    z: Float(z) / 4)))
                list.append(s)
            }
        }
    }
    return HitableList(list:list)
}

func random_scene() -> HitableList {
    var list = [Hitable]()
    let ground_material = Lambertian(albedo:Vec3(x: 0.5, y: 0.5, z: 0.5))
    list.append(Sphere(center:Vec3(x:0, y: -1000, z:0), radius: 1000.0,
            material:ground_material))
    
    list.append(Sphere(center:Vec3(x:0, y:1, z:0), radius: 1.0,
            material: Dialectric(ir: 1.5)))
    list.append(Sphere(center:Vec3(x:-4, y:1, z:0), radius: 1.0,
            material: Lambertian(albedo: Vec3(x: 0.4, y: 0.2, z: 0.1))))
    list.append(Sphere(center:Vec3(x:4, y:1, z:0), radius: 1.0,
            material: Metal(albedo: Vec3(x: 0.7, y: 0.6, z: 0.5), fuzz: 0.0)))

    for a in -11...11 {
        for b in -11...11 {
            let choose_mat = Float.random(in: 0.0...1.0)
            var r = Vec3.random(in: 0.0...1.0)
            r = Vec3(x: r.x, y: 0.0, z: r.z)
            let center = 0.9 * r + Vec3(x: Float(a), y: 0.2, z: Float(b))
            
            if (center - Vec3(x: 4.0, y: 0.2, z: 0.0)).length() > 0.9 {
                let material:Material = if choose_mat < 0.8 {
                    Lambertian(albedo:
                            Vec3.random(in: 0.0...1.0) *
                            Vec3.random(in: 0.0...1.0))
                } else if choose_mat < 0.95 {
                    Metal(albedo:Vec3.random(in: 0.5...1.0),
                            fuzz: Float.random(in: 0.0...0.5))
                } else {
                    Dialectric(ir: 1.5)
                }
                if choose_mat < 0.8 {
                    let center2 = center + Vec3(x:0, y:Float.random(in: 0.0...0.5), z:0)
                    list.append(Sphere(center1:center, center2: center2, 
                        radius: 0.2, material: material))
                } else {
                    list.append(Sphere(center:center, radius: 0.2, material: material))
                }
             }
        }
    }

    return HitableList(list:list)
}

func sky_fade(_ r:Ray) -> Vec3 {
    let unit_direction = r.direction().normalize()
    let t = 0.5 * (unit_direction.y + 1.0)
    return (1.0 - t) * Vec3.one + t * Vec3(x: 0.5, y: 0.7, z: 1.0)
}

func sky_flat(_ color:Vec3) -> (Ray) -> Vec3 {
    func sky(_ r:Ray) -> Vec3 {
        return color
    }
    return sky
}

func ray_colour(world: Hitable, r: Ray, depth: Int, sky: (Ray)->Vec3) -> Vec3 {
    if depth < 0 {
        return Vec3.zero
    }

    if let rec = world.hit(r: r, ray_t:Interval(t_min: 0.001, t_max: Float.infinity)) {
        if let scattered = rec.material.scatter(r: r, rec: rec) {
            return scattered.attenuation *
                    ray_colour(world: world, r: scattered.ray, depth: depth - 1, sky: sky)
        } else {
            return Vec3.zero
        }
    }
    return sky(r)
}

func write_colour(colour:Vec3, samples_per_pixel:Int) -> (UInt8, UInt8, UInt8) {
    let scale = 1.0 / Float(samples_per_pixel)
    let scaled = colour * scale
    let gamma_corrected = Vec3(x:  scaled.x.squareRoot(),
                                y: scaled.y.squareRoot(),
                                z: scaled.z.squareRoot())
    let two55 = 255.0 * gamma_corrected.clamp(vmin: Vec3.zero, vmax: Vec3.one)
    return (
        UInt8(two55.x),
        UInt8(two55.y),
        UInt8(two55.z)
    )
}

public func render() {
    let samples_per_pixel = 50
    let max_depth = 50

    let aspect_ratio = 16.0 / 9.0
    let image_width = 600
    let image_height = Int(Double(image_width) / aspect_ratio)

    var img = Image(width: image_width, height: image_height)

    let look_from = Vec3(x: 13, y: 2, z: 3)
    //let look_from = Vec3(x: 0, y: 0, z: 50)
    let look_at = Vec3(x: 0, y: 0, z: 0)
    let camera = Camera(
        look_from: look_from,
        look_at: look_at,
        vup: Vec3(x: 0, y: 1, z: 0),
        fov: 20, 
        aspect_ratio: Float(aspect_ratio),
        aperture: 0.1,
        focus_dist: 10)

    let world = BVHNode(list:random_scene())
    //let world = random_scene()
    let sky = sky_fade
    //let world = BVHNode(list:debug_simple_sphere_scene())
    //let world = debug_white_sphere_scene()
    //let sky = sky_flat(Vec3(x:0.0, y:0.0, z:1.0))
    //let hit_list = BVHNode(list:world)
    let hit_list = world

    let total_pixels = image_width * image_height

    for j in 0..<image_height {
        for i in 0..<image_width {
            var pixel_colour = Vec3.zero
            for _ in 0...samples_per_pixel {
                let a = Float.random(in: 0...1)
                let b = Float.random(in: 0...1)
                let u = (Float(i) + a) / (Float(image_width) - 1.0)
                let v = 1.0 - (Float(j) + b) / (Float(image_height) - 1.0)
                let r = camera.get_ray(s: u, t: v)
                pixel_colour = pixel_colour + ray_colour(world: hit_list, r: r, depth: max_depth,
                    sky: sky)

            }
            img.set_pixel(x: i, y: j, val: write_colour(colour: pixel_colour, samples_per_pixel: samples_per_pixel))
            let percentage_complete = (j * image_width + i) * 100 / total_pixels
            print("\r\(percentage_complete) % complete\r", terminator:"") 
        }
    }
    print("")
    img.write(file: "/Users/jeremythorne/dev/swift-raytracing/out.tga")
}

