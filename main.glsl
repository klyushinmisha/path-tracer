#define FAR_DISTANCE 1000000.0
#define SPHERE_COUNT 4
#define PLANE_COUNT 5
#define MAX_DEPTH 8
#define PI 3.1415926535
#define ORIGIN_BIAS 0.8
#define ITERATIONS 10
#define FOV 1.

vec2 Seed;

void initRandom(vec2 seed) {
    Seed = seed;
}

float rand(){
    float f = fract(sin(dot(Seed, vec2(12.9898, 78.233))) * 43758.5453);
    Seed += vec2(0.1);
    return f;
}

vec2 Random2D() {
    return normalize(vec2(rand(), rand()));
}

vec3 Random3D() {
    return normalize(vec3(rand(), rand(), rand()));
}

vec3 uniformRandomPoint(vec2 randAngles) {
    float phi = 2. * PI * randAngles.x;
    float theta = 2. * PI * randAngles.y;
    return vec3(
        cos(phi) * sin(theta),
        cos(phi) * cos(theta),
        sin(phi)
    );
}

vec3 hemispherePoint(vec3 v, vec3 n) {
    vec3 randV = normalize(2. * Random3D() - 1.);
    vec3 tangent = cross(n, randV);
    vec3 bitangent = cross(n, tangent);
    mat3 transform = mat3(tangent, bitangent, n);
    return transform * v;
}

vec2 ndc(vec2 pos, vec2 screen) {
    return vec2(
        2. * (pos.x + .5) / screen.x - 1.,
        2. * (pos.y + .5) / screen.y - 1.
    );
}

vec3 perspective(vec3 pos, vec2 screen) {
    float ar = screen.x / screen.y;
    return vec3(
        pos.x * tan(FOV / 2.) * ar / pos.z,
        pos.y * tan(FOV / 2.) / pos.z,
        pos.z
    );
}

struct Material {
    vec3 emmitance;
    vec3 reflectance;
    float roughness;
    float opacity;
};

struct Sphere {
    Material mat;
    vec3 pos;
    float r;
};

struct Plane {
    Material mat;
    vec4 pos;
};

Sphere spheres[SPHERE_COUNT];
Plane planes[PLANE_COUNT];

void initScene() {
    Material mat_0 = Material(vec3(0.2), vec3(1), .6, 1.);
    Material mat_1 = Material(vec3(.1), vec3(1), .4, .3);
    Material mat_2 = Material(normalize(vec3(0.3, 0.5, 0.)), vec3(.2, .3, .4), .1, .1);
    Material mat_3 = Material(normalize(vec3(0.5, 0.3, 0.)), vec3(.2, .3, .4), .1, .1);
    Material mat_4 = Material(normalize(vec3(0.5, 0, 0.7)), vec3(.2, .3, .4), .1, .1);
    Material mat_5 = Material(vec3(0.1), vec3(1), .0, 1.);
    Material mat_6 = Material(vec3(0.3), vec3(0.1), .0, 1.);
    Material mat_7 = Material(vec3(0.1), vec3(0.1), .0, 1.);

    spheres[0] = Sphere(mat_0, vec3(0, -1, 7.), 1.);
    spheres[1] = Sphere(mat_0, vec3(-1, -1, 4.), .5);
    spheres[2] = Sphere(mat_3, vec3(1.5, 1, 5.), .5);
    spheres[3] = Sphere(mat_4, vec3(-2, 1, 5.), .5);

    planes[0] = Plane(mat_6, vec4(0, -1, 0, -2));
    planes[1] = Plane(mat_6, vec4(0, 1, 0, -2));
    planes[2] = Plane(mat_5, vec4(-1, 0, 0, -4));
    planes[3] = Plane(mat_5, vec4(1, 0, 0, -4));
    planes[4] = Plane(mat_7, vec4(0, 0, 1, -10));
}

bool intersectSphere(vec3 ray, vec3 origin, Sphere sph, out float dist, out vec3 n) {
    vec3 L = sph.pos - origin;
    float a = 1.;
    float b = dot(ray, L);
    float c = dot(L, L) - sph.r*sph.r;
    float d = b*b - a*c;
    if (d < 0.) {
        return false;
    }
    float x1 = b - sqrt(d);
    float x2 = b + sqrt(d);
    if (x1 > 0.) {
        dist = x1;
    } else if (x2 > 0.) {
        dist = x2;
    } else {
        return false;
    }
    n = normalize(dist * ray - L);
    return true;
}

bool intersectPlane(vec3 ray, vec3 origin, Plane plane, out float dist, out vec3 n) {
    n = plane.pos.xyz;
    float w = plane.pos.w;
    dist = -(dot(origin, n) + w) / dot(ray, n);
    return length(cross(n, ray.xyz)) != 0. && dist > 0.;
}

bool castRay(vec3 ray, vec3 origin, out float dist, out vec3 norm, out Material mat) {
    dist = FAR_DISTANCE;
    float d;
    vec3 n;
    for (int i = 0; i < SPHERE_COUNT; i++) {
        Sphere sph = spheres[i];
        if (intersectSphere(ray, origin, sph, d, n) && d < dist) {
            dist = d;
            norm = n;
            mat = sph.mat;
        }
    }
    for (int i = 0; i < PLANE_COUNT; i++) {
        Plane plane = planes[i];
        if (intersectPlane(ray, origin, plane, d, n) && d < dist) {
            dist = d;
            norm = n;
            mat = plane.mat;
        }
    }
    return dist != FAR_DISTANCE;
}

vec3 tracePath(vec3 ray, vec3 origin) {
    vec3 L = vec3(0);
    vec3 F = vec3(1);
    for (int i = 0; i < MAX_DEPTH; i++) {
        vec3 n;
        float d;
        Material mat;
        if (castRay(ray, origin, d, n, mat)) {
            L += F * mat.emmitance;
            F *= mat.reflectance;

            origin += d * ray + ORIGIN_BIAS * n;
            vec3 rayBias = hemispherePoint(
                uniformRandomPoint(
                    Random2D()
                ),
                n
            );
            vec3 idealRayReflect = reflect(ray, n);
            ray = normalize(mix(rayBias, idealRayReflect, mat.roughness));
        } else {
            F = vec3(0);
        }
    }
    return L;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    initRandom(fragCoord);
    initScene();

    float w = iResolution.x;
    float h = iResolution.y;
    float z = 1.;
    
    vec3 cam = normalize(
        perspective(
            vec3(ndc(fragCoord.xy, iResolution.xy), z),
            iResolution.xy
        )
    );

    for (int i = 0; i < ITERATIONS; i++) {
        fragColor += vec4(tracePath(cam, vec3(0)), 1.);
    }
    fragColor /= vec4(ITERATIONS);
}
