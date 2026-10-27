/**
 * @module client/features/landing/worldLandPolygons
 * @layer Model (Geographic Landmass Polygons & 3D Projection Math)
 * @purpose Provides real geographic continent and island coastline contours ([lon, lat]),
 *          densified spherical coastline rings, point-in-polygon landmass dot lattices,
 *          and custom 2D jetliner vector rendering for GlobalRefundGlobe.
 */

export type LonLat = readonly [lon: number, lat: number];

/**
 * Simplified natural world landmass coastline rings ([longitude, latitude] in degrees).
 * Designed so East Asia (Korea, Japan, China, Taiwan, SE Asia), North/South America,
 * Europe/UK, Africa, and Oceania render with immediately recognizable real coastlines.
 */
const RAW_WORLD_POLYGONS: ReadonlyArray<ReadonlyArray<LonLat>> = [
	// Korean Peninsula (distinctly separated by Yellow Sea & East Sea)
	[
		[126.1, 34.3],
		[127.8, 34.6],
		[129.2, 35.1],
		[129.5, 36.1],
		[129.1, 37.5],
		[128.4, 38.6],
		[127.6, 39.2],
		[128.6, 40.2],
		[129.9, 41.0],
		[130.7, 42.3],
		[129.6, 42.6],
		[128.0, 41.9],
		[126.5, 41.2],
		[124.3, 39.9],
		[125.2, 38.7],
		[126.1, 37.7],
		[126.6, 36.5],
		[126.3, 35.3],
	],
	// Japan - Hokkaido
	[
		[140.0, 41.5],
		[141.2, 42.0],
		[143.3, 42.1],
		[145.6, 43.3],
		[144.2, 44.3],
		[141.9, 45.4],
		[140.3, 43.2],
	],
	// Japan - Honshu & Shikoku
	[
		[130.9, 34.0],
		[132.6, 33.4],
		[134.8, 33.5],
		[136.9, 34.3],
		[139.8, 35.2],
		[140.9, 35.8],
		[141.0, 38.3],
		[142.0, 39.7],
		[141.2, 41.4],
		[139.9, 40.5],
		[138.9, 37.9],
		[136.7, 37.3],
		[135.4, 35.6],
		[132.4, 35.2],
	],
	// Japan - Kyushu
	[
		[129.7, 33.2],
		[131.0, 33.9],
		[131.8, 32.8],
		[130.8, 31.1],
		[130.1, 31.6],
	],
	// Taiwan
	[
		[120.1, 23.1],
		[120.8, 21.9],
		[121.6, 23.9],
		[121.9, 25.1],
		[120.9, 24.8],
	],
	// Hainan
	[
		[108.6, 18.5],
		[109.6, 18.2],
		[111.0, 19.8],
		[109.8, 20.1],
	],
	// Philippines (Luzon + Mindanao)
	[
		[120.0, 16.2],
		[121.0, 13.7],
		[123.9, 13.0],
		[122.4, 16.8],
		[122.2, 18.5],
		[120.5, 18.3],
	],
	[
		[122.0, 7.1],
		[125.6, 6.1],
		[126.5, 8.2],
		[125.4, 9.8],
		[123.2, 8.5],
	],
	// Eurasia Mainland (Iberia -> Europe -> Siberia -> China -> SE Asia -> India -> Arabia -> Med)
	[
		[-9.3, 38.7],
		[-8.8, 42.9],
		[-1.8, 43.4],
		[-4.5, 48.3],
		[1.8, 51.0],
		[5.5, 53.3],
		[8.6, 54.0],
		[8.5, 57.1],
		[10.5, 57.7],
		[10.2, 54.4],
		[14.2, 54.0],
		[19.0, 54.5],
		[24.0, 57.0],
		[28.0, 60.2],
		[21.5, 61.5],
		[22.5, 65.5],
		[18.5, 63.0],
		[17.5, 59.0],
		[13.0, 55.5],
		[11.0, 59.0],
		[5.2, 60.4],
		[6.5, 63.0],
		[14.0, 67.5],
		[20.5, 70.0],
		[28.0, 71.0],
		[38.0, 68.5],
		[44.0, 67.0],
		[56.0, 69.0],
		[68.0, 71.5],
		[80.0, 72.5],
		[96.0, 75.5],
		[112.0, 73.5],
		[130.0, 71.8],
		[150.0, 70.8],
		[170.0, 68.8],
		[179.0, 66.0],
		[170.0, 60.5],
		[162.5, 56.0],
		[156.8, 51.2],
		[158.5, 55.5],
		[151.0, 59.5],
		[142.0, 59.0],
		[139.0, 54.0],
		[140.5, 49.0],
		[135.5, 44.0],
		[131.2, 42.7],
		[124.2, 40.0],
		[121.3, 38.9],
		[119.5, 39.8],
		[117.8, 38.5],
		[122.4, 37.0],
		[119.5, 34.8],
		[121.8, 31.2],
		[121.6, 28.5],
		[119.5, 25.5],
		[116.5, 23.2],
		[114.2, 22.3],
		[110.2, 20.3],
		[108.2, 21.5],
		[105.8, 19.5],
		[108.4, 15.8],
		[109.2, 12.2],
		[104.8, 8.8],
		[101.0, 13.2],
		[100.2, 8.2],
		[103.8, 1.4],
		[101.2, 3.2],
		[98.4, 8.0],
		[97.6, 16.2],
		[94.3, 16.0],
		[92.0, 21.5],
		[88.5, 21.8],
		[85.2, 19.5],
		[80.3, 13.0],
		[77.6, 8.1],
		[74.8, 13.0],
		[72.8, 19.0],
		[69.0, 22.4],
		[67.0, 24.9],
		[61.5, 25.2],
		[56.4, 26.2],
		[51.5, 25.3],
		[48.2, 29.9],
		[56.0, 27.1],
		[59.6, 22.5],
		[54.0, 17.0],
		[45.0, 12.8],
		[43.3, 12.7],
		[39.1, 21.5],
		[34.5, 28.0],
		[32.6, 30.0],
		[35.2, 32.8],
		[36.0, 36.5],
		[32.5, 36.2],
		[27.2, 36.8],
		[26.2, 40.0],
		[23.8, 38.0],
		[20.0, 39.5],
		[18.0, 42.5],
		[13.8, 45.5],
		[12.5, 44.0],
		[16.2, 41.2],
		[18.4, 40.1],
		[15.6, 38.1],
		[12.4, 41.8],
		[9.0, 44.4],
		[5.0, 43.3],
		[3.1, 42.4],
		[-0.4, 39.4],
		[-5.4, 36.0],
	],
	// Great Britain & Ireland
	[
		[-5.5, 50.1],
		[1.4, 51.3],
		[1.7, 52.6],
		[-0.2, 54.2],
		[-2.0, 57.6],
		[-5.0, 58.6],
		[-5.6, 56.5],
		[-3.2, 54.0],
		[-4.8, 51.6],
	],
	[
		[-10.2, 51.8],
		[-6.2, 52.2],
		[-5.8, 54.6],
		[-8.4, 55.2],
		[-9.9, 53.5],
	],
	// Maritime SE Asia (Sumatra, Borneo, Java, Sulawesi, New Guinea)
	[
		[95.3, 5.5],
		[99.5, 3.5],
		[104.5, -1.5],
		[105.8, -5.8],
		[102.0, -4.0],
		[98.0, 1.0],
	],
	[
		[109.0, 1.5],
		[111.8, 3.0],
		[117.2, 6.8],
		[118.8, 4.5],
		[117.5, 0.5],
		[116.0, -3.5],
		[111.5, -3.2],
		[109.3, -0.5],
	],
	[
		[105.5, -6.5],
		[110.5, -6.8],
		[114.4, -7.8],
		[113.8, -8.6],
		[108.0, -7.8],
	],
	[
		[119.2, -5.2],
		[120.5, 0.8],
		[125.0, 1.5],
		[122.8, -4.5],
	],
	[
		[131.0, -1.2],
		[136.0, -2.2],
		[141.0, -2.6],
		[147.5, -6.5],
		[150.5, -10.2],
		[146.5, -9.2],
		[141.0, -8.8],
		[136.0, -5.0],
	],
	// Australia & New Zealand
	[
		[114.1, -21.9],
		[122.2, -18.0],
		[129.5, -14.2],
		[131.0, -12.2],
		[136.8, -12.3],
		[136.0, -15.5],
		[140.8, -17.5],
		[142.5, -10.8],
		[145.5, -15.5],
		[149.2, -21.0],
		[153.5, -27.5],
		[151.2, -33.9],
		[149.8, -37.5],
		[145.0, -38.4],
		[138.5, -35.2],
		[135.5, -34.8],
		[131.0, -31.5],
		[123.5, -33.8],
		[115.6, -34.3],
		[115.0, -31.0],
		[113.5, -25.8],
	],
	[
		[172.7, -34.5],
		[175.6, -36.8],
		[178.4, -37.7],
		[175.2, -41.4],
		[173.8, -39.3],
	],
	[
		[166.5, -45.8],
		[170.5, -45.9],
		[174.0, -41.5],
		[171.5, -41.8],
	],
	// Africa & Madagascar
	[
		[-5.8, 35.8],
		[3.0, 36.8],
		[10.2, 37.2],
		[11.2, 33.2],
		[20.0, 32.8],
		[29.9, 31.2],
		[32.5, 29.9],
		[35.5, 24.0],
		[39.0, 18.0],
		[43.2, 12.4],
		[51.3, 11.9],
		[49.0, 6.0],
		[41.0, -1.5],
		[39.5, -7.0],
		[40.5, -15.0],
		[35.0, -20.0],
		[35.4, -24.0],
		[31.0, -29.8],
		[25.6, -33.9],
		[18.5, -34.3],
		[17.9, -29.0],
		[14.5, -22.8],
		[12.2, -16.0],
		[13.2, -8.8],
		[9.4, 0.4],
		[9.6, 4.0],
		[3.4, 6.4],
		[-4.0, 5.2],
		[-7.7, 4.4],
		[-13.5, 9.5],
		[-17.4, 14.7],
		[-16.5, 20.8],
		[-13.2, 27.8],
		[-9.8, 31.5],
	],
	[
		[43.3, -24.8],
		[47.0, -25.0],
		[50.4, -15.2],
		[49.3, -12.0],
		[46.3, -15.8],
		[44.0, -20.2],
	],
	// North America & Greenland & Cuba
	[
		[-166.0, 60.0],
		[-162.0, 66.5],
		[-156.5, 71.2],
		[-140.0, 69.6],
		[-126.0, 70.2],
		[-110.0, 68.5],
		[-95.0, 68.5],
		[-82.0, 67.0],
		[-78.0, 63.0],
		[-88.0, 63.5],
		[-94.0, 59.0],
		[-82.0, 55.0],
		[-78.5, 58.5],
		[-72.0, 61.5],
		[-64.5, 60.2],
		[-55.8, 52.2],
		[-64.0, 49.5],
		[-60.5, 46.0],
		[-66.0, 44.5],
		[-70.2, 42.0],
		[-74.0, 40.6],
		[-75.5, 36.8],
		[-80.8, 32.0],
		[-80.2, 25.6],
		[-81.8, 25.2],
		[-82.8, 28.2],
		[-84.5, 29.8],
		[-89.5, 29.2],
		[-95.0, 29.0],
		[-97.5, 25.8],
		[-96.2, 19.2],
		[-90.5, 19.8],
		[-87.0, 21.4],
		[-88.2, 16.0],
		[-83.5, 15.0],
		[-83.0, 10.0],
		[-79.5, 9.0],
		[-78.0, 7.8],
		[-83.0, 8.5],
		[-87.8, 13.2],
		[-92.2, 14.5],
		[-97.0, 15.8],
		[-105.2, 20.5],
		[-109.5, 25.5],
		[-113.0, 31.2],
		[-110.0, 23.0],
		[-114.5, 28.0],
		[-117.2, 32.6],
		[-120.5, 34.5],
		[-122.5, 37.8],
		[-124.2, 42.0],
		[-124.5, 47.8],
		[-130.0, 53.5],
		[-136.5, 58.2],
		[-147.0, 60.5],
		[-153.0, 58.5],
		[-162.0, 55.2],
	],
	[
		[-44.0, 60.0],
		[-22.0, 70.0],
		[-20.0, 78.0],
		[-38.0, 82.5],
		[-60.0, 80.5],
		[-68.0, 76.0],
		[-53.0, 68.5],
		[-51.0, 63.0],
	],
	[
		[-84.9, 21.8],
		[-79.5, 22.8],
		[-74.2, 20.2],
		[-78.0, 20.8],
	],
	// South America
	[
		[-77.5, 8.2],
		[-75.5, 10.8],
		[-71.5, 12.0],
		[-62.0, 10.5],
		[-52.0, 4.8],
		[-48.5, -1.2],
		[-41.0, -2.8],
		[-35.0, -6.0],
		[-38.5, -13.0],
		[-39.5, -18.0],
		[-43.2, -23.0],
		[-48.6, -27.5],
		[-53.5, -33.8],
		[-58.0, -38.0],
		[-63.0, -41.0],
		[-65.8, -47.8],
		[-68.5, -52.5],
		[-67.2, -55.2],
		[-73.5, -52.0],
		[-74.5, -45.0],
		[-73.2, -37.0],
		[-71.6, -30.0],
		[-70.5, -21.0],
		[-75.5, -15.0],
		[-78.5, -9.0],
		[-81.2, -4.6],
		[-80.0, 0.5],
	],
];

const DEG_TO_RAD = Math.PI / 180;

export interface Vec3 {
	x: number;
	y: number;
	z: number;
}

export function latLonToUnitVec3(lat: number, lon: number): Vec3 {
	const phi = (90 - lat) * DEG_TO_RAD;
	const theta = (lon + 180) * DEG_TO_RAD;
	return {
		x: -Math.sin(phi) * Math.cos(theta),
		y: Math.cos(phi),
		z: Math.sin(phi) * Math.sin(theta),
	};
}

/**
 * Subdivides polygon edges so segments stay smooth when projected onto a 3D sphere.
 */
function densifyRing(ring: ReadonlyArray<LonLat>, maxStepDeg = 2.6): Vec3[] {
	const result: Vec3[] = [];
	for (let i = 0; i < ring.length; i += 1) {
		const [lon1, lat1] = ring[i] ?? [0, 0];
		const [lon2, lat2] = ring[(i + 1) % ring.length] ?? [0, 0];
		const dLon = lon2 - lon1;
		const dLat = lat2 - lat1;
		const dist = Math.hypot(dLon, dLat);
		const steps = Math.max(1, Math.ceil(dist / maxStepDeg));
		for (let s = 0; s < steps; s += 1) {
			const ratio = s / steps;
			result.push(latLonToUnitVec3(lat1 + dLat * ratio, lon1 + dLon * ratio));
		}
	}
	return result;
}

function pointInRing(lon: number, lat: number, ring: ReadonlyArray<LonLat>) {
	let inside = false;
	for (let i = 0, j = ring.length - 1; i < ring.length; j = i, i += 1) {
		const [xi, yi] = ring[i] ?? [0, 0];
		const [xj, yj] = ring[j] ?? [0, 0];
		const intersects =
			yi > lat !== yj > lat &&
			lon < ((xj - xi) * (lat - yi)) / (yj - yi + 1e-9) + xi;
		if (intersects) {
			inside = !inside;
		}
	}
	return inside;
}

function isPointOnRealLand(lon: number, lat: number): boolean {
	for (const ring of RAW_WORLD_POLYGONS) {
		if (pointInRing(lon, lat, ring)) {
			return true;
		}
	}
	return false;
}

export const WORLD_SPHERE_RINGS: ReadonlyArray<ReadonlyArray<Vec3>> =
	RAW_WORLD_POLYGONS.map((ring) => densifyRing(ring));

export const WORLD_LAND_DOTS: ReadonlyArray<Vec3> = (() => {
	const dots: Vec3[] = [];
	for (let lat = -54; lat <= 76; lat += 2.6) {
		const lonStep = 2.6 / Math.max(0.32, Math.cos(Math.abs(lat) * DEG_TO_RAD));
		for (let lon = -178; lon <= 178; lon += lonStep) {
			if (isPointOnRealLand(lon, lat)) {
				dots.push(latLonToUnitVec3(lat, lon));
			}
		}
	}
	return dots;
})();

/**
 * Draws a crisp top-down commercial jetliner silhouette oriented along `angleRad`
 * (0 rad = pointing +X right).
 */
export function drawAirplaneSilhouette(
	ctx: CanvasRenderingContext2D,
	x: number,
	y: number,
	angleRad: number,
	scale: number,
	isHighlighted: boolean,
) {
	ctx.save();
	ctx.translate(x, y);
	ctx.rotate(angleRad);
	ctx.scale(scale, scale);

	// Soft ambient halo beneath aircraft
	const halo = ctx.createRadialGradient(0, 0, 1, 0, 0, isHighlighted ? 16 : 11);
	halo.addColorStop(
		0,
		isHighlighted ? "rgba(96, 165, 250, 0.65)" : "rgba(147, 197, 253, 0.35)",
	);
	halo.addColorStop(1, "rgba(59, 130, 246, 0)");
	ctx.fillStyle = halo;
	ctx.beginPath();
	ctx.arc(0, 0, isHighlighted ? 16 : 11, 0, Math.PI * 2);
	ctx.fill();

	// Swept-wing jetliner fuselage + wings + tailplane
	ctx.beginPath();
	ctx.moveTo(9.5, 0); // Nose cone
	ctx.lineTo(4.2, 1.55); // Forward fuselage
	ctx.lineTo(-1.8, 9.2); // Right wingtip
	ctx.lineTo(-4.0, 9.2);
	ctx.lineTo(-1.4, 1.65); // Right wing root
	ctx.lineTo(-6.2, 1.2); // Rear fuselage
	ctx.lineTo(-8.8, 4.4); // Right horizontal stabilizer
	ctx.lineTo(-10.2, 4.4);
	ctx.lineTo(-8.6, 0.6);
	ctx.lineTo(-9.6, 0); // Tail cone
	ctx.lineTo(-8.6, -0.6);
	ctx.lineTo(-10.2, -4.4); // Left horizontal stabilizer
	ctx.lineTo(-8.8, -4.4);
	ctx.lineTo(-6.2, -1.2);
	ctx.lineTo(-1.4, -1.65); // Left wing root
	ctx.lineTo(-4.0, -9.2); // Left wingtip
	ctx.lineTo(-1.8, -9.2);
	ctx.lineTo(4.2, -1.55);
	ctx.closePath();

	ctx.fillStyle = isHighlighted ? "#ffffff" : "rgba(241, 245, 249, 0.92)";
	ctx.fill();

	if (isHighlighted) {
		ctx.strokeStyle = "rgba(59, 130, 246, 0.85)";
		ctx.lineWidth = 0.8;
		ctx.stroke();
	}

	ctx.restore();
}
