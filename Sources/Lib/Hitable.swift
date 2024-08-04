import Foundation // for tan()

public struct Ray {
    let a: Vec3
    let b: Vec3
    let tm: Double

    public init(a: Vec3, b: Vec3) {
        self.a = a
        self.b = b
        tm = 0.0
    }

    init(a: Vec3, b: Vec3, tm: Double) {
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

    func time() -> Double {
        return tm
    }

    func point_at_parameter(t: Double) -> Vec3 {
        return a + t * b
    }
}

public struct AttenuatedRay {
    let attenuation: Vec3
    let ray: Ray
}

public struct HitRecord {
    public let t: Double
    public let p: Vec3
    public let front_face: Bool
    public let normal: Vec3
    public let material: Material
    public let u: Double = 0
    public let v: Double = 0

    init(t: Double, p: Vec3, r: Ray, outward_normal: Vec3,
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
    public let t_min:Double
    public let t_max:Double

    public init() {
        t_min = 0.0
        t_max = 0.0
    }

    public init(t_min: Double, t_max:Double) {
        self.t_min = t_min
        self.t_max = t_max
    }

    public init(a:Interval, b:Interval) {
        // create the interval tightly enclosing the two input intervals
        t_min = a.t_min <= b.t_min ? a.t_min : b.t_min
        t_max = a.t_max >= b.t_max ? a.t_max : b.t_max
    }

    public func expand(delta:Double) -> Interval {
        let padding = delta/2.0
        return Interval(t_min:t_min - padding, t_max:t_max + padding)
    }

    public func size() -> Double {
        return t_max - t_min
    }

    static let empty = Interval(t_min: Double.infinity, t_max: -1.0 * Double.infinity)
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

public protocol Hitable {
    func hit(r: Ray, ray_t:Interval) -> HitRecord?
    func bounding_box() -> AABB
}

public struct Sphere : Hitable {
    let center1: Vec3
    let radius: Double
    let material: Material
    let center_vec: Vec3
    let is_moving: Bool
    let bbox: AABB

    public init(center: Vec3, radius: Double, material: Material) {
        self.center1 = center
        self.radius = max(0.0, radius)
        self.material = material
        is_moving = false
        center_vec = Vec3.zero
        let rvec = Vec3(x:radius, y: radius, z:radius)
        bbox = AABB(a:center1 - rvec, b: center1 + rvec)
    }

    init(center1: Vec3, center2: Vec3, radius: Double, material: Material) {
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

    func sphere_center(time: Double) -> Vec3 {
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

