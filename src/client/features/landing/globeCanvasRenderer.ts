/**
 * @module client/features/landing/globeCanvasRenderer
 * @layer View Engine (3D Spherical Projection & Flight Corridor Canvas Renderer)
 * @purpose Projects real geographic continent rings, tactile landmass dots, Great-Circle
 *          flight trajectories, contrails, and oriented jetliner silhouettes onto 2D Canvas.
 */

import {
	drawAirplaneSilhouette,
	latLonToUnitVec3,
	type Vec3,
	WORLD_LAND_DOTS,
	WORLD_SPHERE_RINGS,
} from "@/client/features/landing/worldLandPolygons";
import type { ClaimKind, CurrencyCode } from "@/client/types";

export interface FlightCorridor {
	id: string;
	country: string;
	city: string;
	vendor: string;
	lat: number;
	lon: number;
	targetYaw: number;
	currency: CurrencyCode;
	amount: string;
	displayGain: string;
	statusTag: string;
	kind: ClaimKind;
	issue: string;
}

const SEOUL = { lat: 37.5665, lon: 126.978 };
const SEOUL_VEC = latLonToUnitVec3(SEOUL.lat, SEOUL.lon);

function rotateGlobePoint(p: Vec3, yaw: number, pitch: number): Vec3 {
	const cosY = Math.cos(yaw);
	const sinY = Math.sin(yaw);
	const x1 = p.x * cosY + p.z * sinY;
	const z1 = -p.x * sinY + p.z * cosY;

	const cosP = Math.cos(pitch);
	const sinP = Math.sin(pitch);
	const y2 = p.y * cosP - z1 * sinP;
	const z2 = p.y * sinP + z1 * cosP;

	return { x: x1, y: y2, z: z2 };
}

function slerpElevated(a: Vec3, b: Vec3, t: number, maxLift = 0.17): Vec3 {
	const dot = Math.max(-1, Math.min(1, a.x * b.x + a.y * b.y + a.z * b.z));
	const omega = Math.acos(dot);
	const sinOmega = Math.sin(omega);
	let x: number;
	let y: number;
	let z: number;

	if (sinOmega < 0.0005) {
		x = a.x + (b.x - a.x) * t;
		y = a.y + (b.y - a.y) * t;
		z = a.z + (b.z - a.z) * t;
	} else {
		const w1 = Math.sin((1 - t) * omega) / sinOmega;
		const w2 = Math.sin(t * omega) / sinOmega;
		x = a.x * w1 + b.x * w2;
		y = a.y * w1 + b.y * w2;
		z = a.z * w1 + b.z * w2;
	}

	const lift = 1 + Math.sin(Math.PI * t) * maxLift;
	return { x: x * lift, y: y * lift, z: z * lift };
}

export interface RenderGlobeSceneParams {
	ctx: CanvasRenderingContext2D;
	width: number;
	height: number;
	yaw: number;
	pitch: number;
	phase: number;
	corridors: FlightCorridor[];
	activeIdx: number;
	seoulHubLabel: string;
}

export function renderGlobeScene({
	ctx,
	width,
	height,
	yaw,
	pitch,
	phase,
	corridors,
	activeIdx,
	seoulHubLabel,
}: RenderGlobeSceneParams): void {
	const cx = width * 0.5;
	const cy = height * 0.51;
	const radius = Math.min(width, height) * 0.39;

	// 1. Atmospheric outer aura
	const atmos = ctx.createRadialGradient(
		cx,
		cy,
		radius * 0.82,
		cx,
		cy,
		radius * 1.28,
	);
	atmos.addColorStop(0, "rgba(49, 130, 246, 0.34)");
	atmos.addColorStop(0.55, "rgba(27, 100, 218, 0.11)");
	atmos.addColorStop(1, "rgba(7, 15, 32, 0)");
	ctx.fillStyle = atmos;
	ctx.beginPath();
	ctx.arc(cx, cy, radius * 1.28, 0, Math.PI * 2);
	ctx.fill();

	// 2. Deep ocean sphere body
	const ocean = ctx.createRadialGradient(
		cx - radius * 0.32,
		cy - radius * 0.34,
		radius * 0.08,
		cx,
		cy,
		radius,
	);
	ocean.addColorStop(0, "#1d4587");
	ocean.addColorStop(0.5, "#0d244d");
	ocean.addColorStop(1, "#061126");
	ctx.fillStyle = ocean;
	ctx.beginPath();
	ctx.arc(cx, cy, radius, 0, Math.PI * 2);
	ctx.fill();

	// 3. Clipped spherical interior: graticules + REAL geographic continents + coastlines
	ctx.save();
	ctx.beginPath();
	ctx.arc(cx, cy, radius, 0, Math.PI * 2);
	ctx.clip();

	ctx.strokeStyle = "rgba(148, 163, 184, 0.11)";
	ctx.lineWidth = 0.75;
	for (let lat = -60; lat <= 60; lat += 30) {
		ctx.beginPath();
		let started = false;
		for (let lon = -180; lon <= 180; lon += 6) {
			const r = rotateGlobePoint(latLonToUnitVec3(lat, lon), yaw, pitch);
			if (r.z > 0) {
				const px = cx + r.x * radius;
				const py = cy - r.y * radius;
				if (!started) {
					ctx.moveTo(px, py);
					started = true;
				} else {
					ctx.lineTo(px, py);
				}
			} else {
				started = false;
			}
		}
		ctx.stroke();
	}

	for (const ring of WORLD_SPHERE_RINGS) {
		let visibleCount = 0;
		const projected: Array<{ x: number; y: number; z: number }> = [];

		for (const v of ring) {
			const r = rotateGlobePoint(v, yaw, pitch);
			if (r.z > 0) {
				visibleCount += 1;
				projected.push({
					x: cx + r.x * radius,
					y: cy - r.y * radius,
					z: r.z,
				});
			} else {
				const xyLen = Math.hypot(r.x, r.y) || 1;
				projected.push({
					x: cx + (r.x / xyLen) * radius,
					y: cy - (r.y / xyLen) * radius,
					z: 0,
				});
			}
		}

		if (visibleCount < 2) continue;

		ctx.beginPath();
		projected.forEach((pt, idx) => {
			if (idx === 0) ctx.moveTo(pt.x, pt.y);
			else ctx.lineTo(pt.x, pt.y);
		});
		ctx.closePath();
		ctx.fillStyle = "rgba(59, 130, 246, 0.24)";
		ctx.fill();

		ctx.beginPath();
		let drawingCoast = false;
		for (const pt of projected) {
			if (pt.z > 0.02) {
				if (!drawingCoast) {
					ctx.moveTo(pt.x, pt.y);
					drawingCoast = true;
				} else {
					ctx.lineTo(pt.x, pt.y);
				}
			} else {
				drawingCoast = false;
			}
		}
		ctx.strokeStyle = "rgba(147, 197, 253, 0.65)";
		ctx.lineWidth = 1.15;
		ctx.stroke();
	}

	for (const dot of WORLD_LAND_DOTS) {
		const r = rotateGlobePoint(dot, yaw, pitch);
		if (r.z <= 0.04) continue;
		const px = cx + r.x * radius;
		const py = cy - r.y * radius;
		const alpha = 0.22 + r.z * 0.52;
		ctx.fillStyle = `rgba(191, 219, 254, ${alpha.toFixed(2)})`;
		ctx.beginPath();
		ctx.arc(px, py, 1.15 + r.z * 0.45, 0, Math.PI * 2);
		ctx.fill();
	}

	ctx.restore();

	ctx.strokeStyle = "rgba(147, 197, 253, 0.36)";
	ctx.lineWidth = 1.3;
	ctx.beginPath();
	ctx.arc(cx, cy, radius, 0, Math.PI * 2);
	ctx.stroke();

	// 4. Flight Corridors + Contrails + Flying Airplanes into Seoul
	corridors.forEach((route, idx) => {
		const isFocused = idx === activeIdx;
		const originVec = latLonToUnitVec3(route.lat, route.lon);
		const originRot = rotateGlobePoint(originVec, yaw, pitch);

		const segments = 48;
		const arcPts: Array<{ x: number; y: number; z: number }> = [];
		for (let s = 0; s <= segments; s += 1) {
			const u = s / segments;
			const elevated = slerpElevated(
				originVec,
				SEOUL_VEC,
				u,
				isFocused ? 0.2 : 0.14,
			);
			const rot = rotateGlobePoint(elevated, yaw, pitch);
			arcPts.push({
				x: cx + rot.x * radius,
				y: cy - rot.y * radius,
				z: rot.z,
			});
		}

		ctx.beginPath();
		let startedArc = false;
		for (const pt of arcPts) {
			if (pt.z > -0.18) {
				if (!startedArc) {
					ctx.moveTo(pt.x, pt.y);
					startedArc = true;
				} else {
					ctx.lineTo(pt.x, pt.y);
				}
			} else {
				startedArc = false;
			}
		}
		ctx.strokeStyle = isFocused
			? "rgba(125, 211, 252, 0.58)"
			: "rgba(96, 165, 250, 0.24)";
		ctx.lineWidth = isFocused ? 2.1 : 1.2;
		ctx.stroke();

		if (originRot.z > 0.05) {
			const ox = cx + originRot.x * radius;
			const oy = cy - originRot.y * radius;
			ctx.fillStyle = isFocused ? "#ffffff" : "rgba(186, 230, 253, 0.85)";
			ctx.beginPath();
			ctx.arc(ox, oy, isFocused ? 3.8 : 2.6, 0, Math.PI * 2);
			ctx.fill();

			ctx.font = `${isFocused ? "700" : "600"} 11px "Pretendard Variable", sans-serif`;
			ctx.fillStyle = isFocused ? "#ffffff" : "rgba(226, 232, 240, 0.78)";
			ctx.fillText(route.city, ox + 7, oy + 4);
		}

		const planeProgressList = isFocused
			? [(phase + idx * 0.21) % 1, (phase + idx * 0.21 + 0.5) % 1]
			: [(phase * 0.85 + idx * 0.23) % 1];

		for (const progress of planeProgressList) {
			const trailStart = Math.max(0, progress - 0.17);
			const startIdx = Math.floor(trailStart * segments);
			const endIdx = Math.min(segments, Math.ceil(progress * segments));
			if (endIdx > startIdx) {
				ctx.beginPath();
				let trailOpen = false;
				for (let k = startIdx; k <= endIdx; k += 1) {
					const p = arcPts[k];
					if (p && p.z > -0.1) {
						if (!trailOpen) {
							ctx.moveTo(p.x, p.y);
							trailOpen = true;
						} else {
							ctx.lineTo(p.x, p.y);
						}
					}
				}
				ctx.strokeStyle = isFocused
					? "rgba(255, 255, 255, 0.92)"
					: "rgba(186, 230, 253, 0.62)";
				ctx.lineWidth = isFocused ? 2.8 : 1.7;
				ctx.lineCap = "round";
				ctx.stroke();
			}

			const pos3d = rotateGlobePoint(
				slerpElevated(originVec, SEOUL_VEC, progress, isFocused ? 0.2 : 0.14),
				yaw,
				pitch,
			);
			if (pos3d.z > -0.08) {
				const aheadT = Math.min(1, progress + 0.02);
				const behindT = Math.max(0, progress - 0.02);
				const pAhead = rotateGlobePoint(
					slerpElevated(originVec, SEOUL_VEC, aheadT, isFocused ? 0.2 : 0.14),
					yaw,
					pitch,
				);
				const pBehind = rotateGlobePoint(
					slerpElevated(originVec, SEOUL_VEC, behindT, isFocused ? 0.2 : 0.14),
					yaw,
					pitch,
				);
				const ax = cx + pos3d.x * radius;
				const ay = cy - pos3d.y * radius;
				const dx = (pAhead.x - pBehind.x) * radius;
				const dy = -(pAhead.y - pBehind.y) * radius;
				const angle = Math.atan2(dy, dx);
				const planeScale = isFocused ? 1.08 : 0.82;

				drawAirplaneSilhouette(ctx, ax, ay, angle, planeScale, isFocused);
			}
		}
	});

	// 5. Seoul Destination Beacon
	const seoulRot = rotateGlobePoint(SEOUL_VEC, yaw, pitch);
	if (seoulRot.z > 0) {
		const sx = cx + seoulRot.x * radius;
		const sy = cy - seoulRot.y * radius;
		const pulse = (phase * 2.2) % 1;

		ctx.strokeStyle = `rgba(96, 165, 250, ${(1 - pulse) * 0.85})`;
		ctx.lineWidth = 2;
		ctx.beginPath();
		ctx.arc(sx, sy, 6 + pulse * 18, 0, Math.PI * 2);
		ctx.stroke();

		ctx.fillStyle = "#3182f6";
		ctx.beginPath();
		ctx.arc(sx, sy, 6, 0, Math.PI * 2);
		ctx.fill();

		ctx.fillStyle = "#ffffff";
		ctx.beginPath();
		ctx.arc(sx, sy, 2.8, 0, Math.PI * 2);
		ctx.fill();

		ctx.font = '700 11.5px "Pretendard Variable", sans-serif';
		const textW = ctx.measureText(seoulHubLabel).width;
		const pillX = sx + 11;
		const pillY = sy - 13;
		ctx.fillStyle = "rgba(15, 23, 42, 0.86)";
		ctx.strokeStyle = "rgba(125, 211, 252, 0.65)";
		ctx.lineWidth = 1;
		ctx.beginPath();
		ctx.roundRect(pillX, pillY, textW + 16, 23, 11.5);
		ctx.fill();
		ctx.stroke();

		ctx.fillStyle = "#f8fafc";
		ctx.fillText(seoulHubLabel, pillX + 8, pillY + 15.5);
	}
}
