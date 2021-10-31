#define FAR_DISTANCE 1000000.0
#define SPHERE_COUNT 2
#define MAX_DEPTH 5

vec2 ndc(vec2 pos, vec2 screen) {
    return vec2(
        2. * (pos.x + .5) / screen.x - 1.,
        2. * (pos.y + .5) / screen.y - 1.
    );
}

vec3 perspective(vec3 pos, vec2 screen) {
    float fov = 1.;
    float ar = screen.x / screen.y;
    return vec3(
        pos.x * tan(fov / 2.) * ar / pos.z,
        pos.y * tan(fov / 2.) / pos.z,
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

Sphere spheres[SPHERE_COUNT];

void initScene() {
    Material mat_1 = Material(vec3(.2, .3, .4), vec3(.2, .3, .4), 1., 1.);
    Material mat_2 = Material(vec3(.4, .2, .3), vec3(.2, .3, .4), 1., 1.);
    spheres[0] = Sphere(mat_1, vec3(0, -1, 6.), 1.);
    spheres[1] = Sphere(mat_2, vec3(0, 0, 5.), 1.);
}

bool intersectSphere(vec3 ray, Sphere sph, out float dist, out vec3 n) {
    float a = 1.;
    float b = dot(ray, sph.pos);
    float c = dot(sph.pos, sph.pos) - sph.r*sph.r;
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
    n = normalize(dist * ray - sph.pos);
    return true;
}

bool castRay(vec3 ray, out float dist, out vec3 norm, out Material mat) {
    dist = FAR_DISTANCE;
    for (int i = 0; i < SPHERE_COUNT; i++) {
        Sphere sph = spheres[i];
        float d;
        vec3 n;
        if (intersectSphere(ray, sph, d, n) && d < dist) {
            dist = d;
            norm = n;
            mat = sph.mat;
        } 
    }
    return dist != FAR_DISTANCE;
}

vec3 tracePath(vec3 ray) {
    vec3 L = vec3(0);
    vec3 F = vec3(1);
    for (int i = 0; i < MAX_DEPTH; i++) {
        vec3 n;
        float d;
        Material mat;
        if (castRay(ray, d, n, mat)) {
            L += F * mat.emmitance;
            F *= mat.reflectance;
        } else {
            F = vec3(0);
        }
    }
    return L;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
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

    float d;
    vec3 n;
    Material mat;

    fragColor = vec4(tracePath(cam), 1.);
}
