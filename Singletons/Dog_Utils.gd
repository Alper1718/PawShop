extends Node
class_name DogUtils

const STAT_MAX := 10.0
const BUCKETS := 3

static func stat_to_rating(stat: float) -> int:
	var r = int(ceil((stat / STAT_MAX) * BUCKETS))
	return clamp(r, 1, BUCKETS)

static func rating_range(rating: int) -> Array:
	var step = STAT_MAX / float(BUCKETS)
	var low = (rating - 1) * step
	var high = rating * step
	if rating == BUCKETS:
		high = STAT_MAX
	return [low, high]
	
static func random_stat_for_rating(rating: int) -> float:
	var r = rating_range(rating)
	return randf_range(r[0], r[1])
