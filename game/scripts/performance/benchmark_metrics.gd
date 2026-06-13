class_name BenchmarkMetrics
extends RefCounted
## Pure statistics used by the benchmark and unit tests.


static func summarize(series: PackedFloat64Array) -> Dictionary:
	if series.is_empty():
		return {"mean": 0.0, "p50": 0.0, "p95": 0.0, "p99": 0.0, "worst": 0.0}
	var sorted := series.duplicate()
	sorted.sort()
	var total := 0.0
	for value in sorted:
		total += value
	return {
		"mean": total / float(sorted.size()),
		"p50": percentile(sorted, 0.50),
		"p95": percentile(sorted, 0.95),
		"p99": percentile(sorted, 0.99),
		"worst": sorted[sorted.size() - 1],
	}


static func percentile(sorted: PackedFloat64Array, fraction: float) -> float:
	if sorted.is_empty():
		return 0.0
	var index := clampi(int(ceil(fraction * float(sorted.size()))) - 1, 0, sorted.size() - 1)
	return sorted[index]


static func one_percent_low_fps(frame_times_ms: PackedFloat64Array) -> float:
	if frame_times_ms.is_empty():
		return 0.0
	var sorted := frame_times_ms.duplicate()
	sorted.sort()
	var slow_count := maxi(int(ceil(float(sorted.size()) * 0.01)), 1)
	var slow_total := 0.0
	for index in range(sorted.size() - slow_count, sorted.size()):
		slow_total += sorted[index]
	var slow_mean := slow_total / float(slow_count)
	return 1000.0 / slow_mean if slow_mean > 0.0 else 0.0


static func peak(series: PackedFloat64Array) -> float:
	var highest := 0.0
	for value in series:
		highest = maxf(highest, value)
	return highest
