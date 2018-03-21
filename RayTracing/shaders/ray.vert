#version 430

layout(location = 0) in vec2 VertexPosition;
out vec3 Colour;

struct Sphere {
	vec4 center;
	vec4 diffuseColor;
	vec4 specularColor;
	float phongExp;
	float radius;
};

struct Plane {
	vec4 norm;
	vec4 point;
	vec4 diffuseColor;
	vec4 specularColor;
	float phongExp;
};

struct Triangle{
	vec4 A;
	vec4 B;
	vec4 C;
	vec4 diffuseColor;
	vec4 specularColor;
	float phongExp;
};

struct Light {
	vec4 center;
	vec4 color;
	float radius;
	float intensity;
};

layout(std140, binding = 1) uniform SphereData {
	Sphere sphere[50];
};
layout(std140, binding = 2) uniform TriangleData {
	Triangle triangle[50];
};
layout(std140, binding = 3) uniform PlaneData {
	Plane plane[50];
};
layout(std140, binding = 4) uniform LightData {
	Light light[50];
};

//for iterating over
uniform int numSpheres; 
uniform int numTriangles;
uniform int numPlanes;
uniform int numLights;

const int numBounce = 2;
const vec3 ambientLight = vec3(0.1,0.1,0.1);
uniform vec3 cameraOrigin;
uniform float fov;

const float pi = 3.1415926535897931;

//the tracing operation; returns pixel color
vec3 trace(vec3 origin, vec3 ray, int depth);
//calculate a direction vector from which px on screen we are rendering
vec3 directionFromPixel(vec2 pixel);
float vecToMagnitude(vec3 v);
//determine intersection point for ray, and selected shape in selected shape index
float intersectSphere(vec3, vec3, int);
float intersectPlane(vec3, vec3, int );
float intersectTriangle(vec3, vec3, int);

float rand(vec2 co);
void main(){

	gl_Position = vec4(VertexPosition, 0.0, 1.0);

	vec3 dir = directionFromPixel(VertexPosition);
	
	Colour = trace(cameraOrigin, dir, 10);
}

vec3 trace(vec3 origin, vec3 ray, int depth){
	/**
	 * find the nearest instersection point:
	 	For each object, find it's intersection point, take t = minimum
	 */
	
/*
	float min = -1;
	vec3 chosenColor = vec3(0,0,0);
	int objectType = -1; //0 = sphere; 1 = plane; 2 = triangle
	Sphere sObj;
	Plane pObj;
	Triangle tObj;
	
	for (int i = 0; i < numSpheres; i++){ //iterate over spheres
		float t = intersectSphere(cameraOrigin, ray, i);
		if (t > 0 && (min < 0 || t < min)){ 
			min = t; //if min has not been set
			chosenColor = sphere[i].diffuseColor.rgb;
		}
	}

	for (int i = 0; i < numPlanes; i++){ //iterate over planes
		float t = intersectPlane(cameraOrigin, ray, i);
		if (t > 0 && (min < 0 || t < min)){ 
			min = t; //if min has not been set
			chosenColor = plane[i].diffuseColor.rgb;
		}
	}

	for (int i = 0; i < numTriangles; i++){ //iterate over triangles
		float t = intersectTriangle(cameraOrigin, ray, i);
		if (t > 0 && (min < 0 || t < min)){ 
			min = t; //if min has not been set
			chosenColor = triangle[i].diffuseColor.rgb;
		}
	}

	//calculate visibility, w/ soft shadows
	int samples = 2;
	vec3 shadow = vec3(0,0,0);
	vec3 p = cameraOrigin + min * ray;
	for (int l = 0; l < numLights; l++){
		for(int n = 0; n < samples; n++){
			float r = 0;
			if (n%2 == 0) {
				r = (VertexPosition.x + VertexPosition.y)/2;
			} else {
				r = -(VertexPosition.x - VertexPosition.y)/2;
			}
			//select a random point in the light source
			float u = rand(vec2(r,n));
			float v = rand(vec2(n-u,n-r));
			float rad = light[l].radius;

			float theta = 2*pi *u;

			float rX = sqrt(1-u*u)*cos(theta);
			float rY = u;
			float rZ = sqrt(1-u*u)*sin(theta);

			vec3 c = light[l].center.xyz + vec3(rX, rY, rZ) * rad * v;
			float dist = sqrt(pow(c.x - p.x, 2) + pow(c.y - p.y, 2) + pow(c.z - p.z, 2));
			vec3 newray = normalize(c-p);

			for (int i = 0; i < numSpheres; i++){ //iterate over spheres
				//move slightly in rayection of normal
				vec3 normal = normalize(sphere[i].center.xyz - p);
				float t = intersectSphere(p + 0.00001*normal, newray, i);
				if (t >= -0.1 && t <= dist){ 
					shadow += vec3(0,0,0);
				} else {
					shadow += vec3(1,1,1)*light[l].intensity;
				}
			}
		}
		shadow = shadow / samples;
	}
	chosenColor = shadow * chosenColor;
	return chosenColor;

*/
	/**
	*Trace Shading here
	*	trace forward path, colecting Cr, 
	*/
	
/*
	vec3 incidentLight[numBounce]; //calculated backwards
	vec3 specularCalc[numBounce];  //max(0, h.n)^p
	float diffuseCalc[numBounce]; //max(0, n.l)
	vec3 diffCol[numBounce];
	vec3 ray = ray;
	for (int b = 0; b < numBounce; b++){
		//----------------------------------------------------------
		//for each ray, find its intersection point with an object:
		float min = -1;
		int objectType = -1; //0 = sphere; 1 = plane; 2 = triangle
		Sphere sObj;
		Plane pObj;
		Triangle tObj;
		
		for (int i = 0; i < numSpheres; i++){ //iterate over spheres
			float t = intersectSphere(origin, ray, i);
			if (t > 0 && (min < 0 || t < min)){ 
				min = t;
				objectType = 0;
				sObj = sphere[i];
			}
		}

		for (int i = 0; i < numPlanes; i++){ //iterate over planes
			float t = intersectPlane(origin, ray, i);
			if (t > 0 && (min < 0 || t < min)){ 
				min = t;
				objectType = 1;
				pObj = plane[i];
			}
		}

		for (int i = 0; i < numTriangles; i++){ //iterate over triangles
			float t = intersectTriangle(origin, ray, i);
			if (t > 0 && (min < 0 || t < min)){ 
				min = t;
				objectType = 2;
				tObj = triangle[i];
			}
		}
		if (min < 0) return vec3(0,0,0);
		
		//--------------------------------
		//calculate the new origin and ray
		origin = origin + min * ray; //the point of intersection;
		if (objectType == 0) {
			vec3 norm = normalize( origin - sObj.center.xyz); //get new norm using new origin
			ray = normalize(ray - 2 * (dot(ray, norm)) * norm); //get new ray using old ray
			diffCol[b] = sObj.diffuseColor.xyz; // save diffuse color of this object
			diffuseCalc[b] = max(0, dot(norm, ray));
			specularCalc[b] = vec3(0,0,0);

			
		} else if (objectType == 1) {
			vec3 norm = normalize(pObj.norm.xyz);
			ray = normalize(ray - 2 * (dot(ray, norm)) * norm);
			diffCol[b] = pObj.diffuseColor.xyz; // save diffuse color of this object
			diffuseCalc[b] = max(0, dot(norm, ray));
			specularCalc[b] = vec3(0,0,0);
		} else if (objectType == 2) {
			vec3 A = tObj.A.xyz;
			vec3 B = tObj.B.xyz;
			vec3 C = tObj.C.xyz;

			vec3 N = B - A;
			vec3 M = C - A;
			vec3 norm = normalize(cross(N,M));
			ray = normalize(ray - 2 * (dot(ray, norm)) * norm);
			diffCol[b] = tObj.diffuseColor.xyz; // save diffuse color of this object
			diffuseCalc[b] = max(0, dot(norm, ray));
			specularCalc[b] = vec3(0,0,0);
		}  
		
	}

	vec3 finalColor = vec3(1,1,1);	
	for (int b = numBounce-1; b >= 0; b--){
		finalColor = diffCol[b] * (ambientLight + finalColor * diffuseCalc[b]);// + finalColor * ambientLight * specularCalc[b];
	}

	return finalColor;
*/
	//for each reflection
	vec3 phong;
	for(int hop = 0; hop < 1; hop++){

		//find intersection point
		
		int objectType = -1; //0 = sphere; 1 = plane; 2 = triangle
		Sphere s;
		Plane p;
		Triangle t;

		float minT = -1;
		for(int i = 0; i < numSpheres; i++){
			float test = intersectSphere(origin, ray, i);
			if (test > 0 && (minT < 0 || test < minT)){ 
				minT = test;
				objectType = 0;
				s = sphere[i];
			}
		}
		for(int i = 0; i < numPlanes; i++){
			float test = intersectPlane(origin, ray, i);
			if (test > 0 && (minT < 0 || test < minT)){ 
				minT = test;
				objectType = 1;
				p = plane[i];
			}			
		}
		for(int i = 0; i < numTriangles; i++){
			float test = intersectTriangle(origin, ray, i);
			if (test > 0 && (minT < 0 || test < minT)){ 
				minT = test;
				objectType = 2;
				t = triangle[i];
			}
		}
		if (minT < 0) return vec3(0, 0, 0);
		
		float phongExp;
		
		vec3 diffuse;
		vec3 specular;
		vec3 normal;

		vec3 intersect = origin + minT * ray;

		
		switch (objectType){
			case 0:
				
				diffuse = s.diffuseColor.xyz;
				specular = s.specularColor.xyz;
				phongExp = s.phongExp;

				normal = normalize(intersect - s.center.xyz);
				break;
			case 1:
				
				diffuse = p.diffuseColor.xyz;
				specular = p.specularColor.xyz;
				phongExp = p.phongExp;

				normal = normalize(p.norm.xyz);
				break;
			case 2:
				
				diffuse = t.diffuseColor.xyz;
				specular = t.specularColor.xyz;
				phongExp = t.phongExp;
				
				vec3 A = t.A.xyz;
				vec3 B = t.B.xyz;
				vec3 C = t.C.xyz;

				vec3 N = B - A;
				vec3 M = C - A;
				normal = normalize(cross(N,M));

				break;
			default:
				//never gonna happen
				break;
		}
		phong += diffuse * ambientLight;
		
		
		
		//calculate phong lighting for each light source
		for (int l = 0; l < numLights; l++){
			//check if in shadow from light, sum shadow
			vec3 shadow = vec3(0,0,0);
			vec3 center = light[l].center.xyz;
			float dist = vecToMagnitude(center - intersect);
			vec3 rLight = normalize(center - intersect);
			

			bool found = false;

			float minTT = -1;
			for(int i = 0; i < numSpheres && !found; i++){
				//move slightly in direction of normal
				vec3 normOffs = normalize(sphere[i].center.xyz - intersect);
				minTT = intersectSphere(intersect + 0.00001 * normal, rLight, i);
				if (minTT >= 0 && minTT<= dist) found = true;
			}

			for(int i = 0; i < numPlanes && !found; i++){
				minTT = intersectPlane(intersect + 0.00001 * normal, rLight, i);
				if (minTT >= 0 && minTT <= dist) found = true;
			}
			
			for(int i = 0; i < numTriangles && !found; i++){
				minTT = intersectTriangle(intersect + 0.00001 * normal, rLight, i);
				if (minTT >= 0 && minTT <= dist) found = true;
			}

			
			if (found){
				shadow =  vec3(0,0,0);
			} else {
				shadow = vec3(1,1,1) * light[l].color.xyz * light[l].intensity;
			}
			
			
			
			vec3 LV = rLight + ray;
			vec3 H = normalize(LV / normalize(LV));
			vec3 R = 2 * (dot(rLight, normal)) *  normal - rLight;
			
			phong += diffuse *(dot(rLight, normal)) * shadow;
			phong += specular * pow(dot(R, -ray), phongExp) * shadow;
		}
	}
	return phong;
	
}



float vecToMagnitude(vec3 v){
	return sqrt(pow(v.x,2) + pow(v.y,2) + pow(v.z,2));
}

vec3 directionFromPixel(vec2 pixel){
	float rads = fov * pi / 180;
	float z = 1 / (2 * tan(rads/2.0));
	vec3 dir = vec3(pixel.x, pixel.y, -z);
	return normalize(dir);
}

float intersectSphere(vec3 origin, vec3 ray, int i){
	
	vec3 d = ray;
	vec3 center = sphere[i].center.xyz;
	vec3 oc = origin - center;
	float r = sphere[i].radius;

	float b = dot(d, oc);
	float c = dot(oc, oc) - r*r;
	
	float disc = b*b - c;
	if (disc < 0) return -1;

	disc = sqrt(disc);
	float t0 = -(b - disc);
	float t1 = -(b + disc);

	if (t0 <= 0) return t1;
	if (t1 <= 0) return t0;
	return (t0 < t1) ? t0 : t1;
}

float intersectPlane(vec3 origin, vec3 ray, int i){
	vec3 o = origin;
	vec3 d = ray;
	vec3 q = plane[i].point.xyz;
	vec3 n = normalize(plane[i].norm.xyz);

	float qn = dot(q,n);
	float on = dot(o,n);
    float dn = dot(d,n);
	float t = (qn - on) / dn;
	return t;
}

float intersectTriangle(vec3 origin, vec3 ray, int i){

	vec3 A = triangle[i].A.xyz;
	vec3 B = triangle[i].B.xyz;
	vec3 C = triangle[i].C.xyz;

	vec3 N = B - A;
	vec3 M = C - A;
	
	vec3 pvec = cross(ray, M);
	float det = dot(N, pvec);

	float invDet = 1/det;

	vec3 tvec = origin - A;
	
	float u = dot(tvec, pvec) * invDet;
	if ( u < 0 || u > 1) return -1;

	vec3 qvec = cross(tvec, N);
	float v = dot(ray, qvec) * invDet;
	if (v < 0 || u + v > 1) return -1;

	float t = dot(M, qvec) * invDet;

	vec3 norm = cross(N, M);

	//same plane calc
	vec3 o = origin;
	vec3 d = ray;
	vec3 q = A;
	vec3 n = normalize(norm);

	float qn = dot(q,n);
	float on = dot(o,n);
    float dn = dot(d,n);
	float p = (qn - on) / dn;
	return p;

}

float rand(vec2 co){
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}