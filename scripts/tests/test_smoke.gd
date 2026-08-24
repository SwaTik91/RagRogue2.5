extends RefCounted

func run() -> Array:
	var errors: Array = []
	if ClassId.Value.MAGE != 1:
		errors.append("MAGE ordinal expected 1")
	return errors
