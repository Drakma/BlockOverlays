private static double blockOverlayPlacementAnchorX(String placement) {
	if (placement.endsWith("_LEFT"))
		return 1.0;
	if (placement.endsWith("_RIGHT"))
		return 0.0;
	return 0.5;
}

private static double blockOverlayPlacementAnchorY(String placement) {
	if (placement.startsWith("TOP_"))
		return 1.0;
	if (placement.startsWith("BOTTOM_"))
		return 0.0;
	return 0.5;
}

private static double blockOverlayPlacementCenterX(String placement, double width) {
	double half = Math.min(0.5, Math.abs(width) / 2.0);
	if (placement.endsWith("_LEFT"))
		return 1.0 - half;
	if (placement.endsWith("_RIGHT"))
		return half;
	return 0.5;
}

private static double blockOverlayPlacementCenterY(String placement, double height) {
	double half = Math.min(0.5, Math.abs(height) / 2.0);
	if (placement.startsWith("TOP_"))
		return 1.0 - half;
	if (placement.startsWith("BOTTOM_"))
		return half;
	return 0.5;
}

private static float blockOverlayPlacementLocalX(String placement, float width) {
	if (placement.endsWith("_LEFT"))
		return 0;
	if (placement.endsWith("_RIGHT"))
		return -width;
	return -width / 2;
}

private static float blockOverlayPlacementLocalY(String placement, float height) {
	if (placement.startsWith("TOP_"))
		return 0;
	if (placement.startsWith("BOTTOM_"))
		return -height;
	return -height / 2;
}

private static double blockOverlayPlacementOffsetX(String placement, double padding) {
	if (placement.endsWith("_LEFT"))
		return padding;
	if (placement.endsWith("_RIGHT"))
		return -padding;
	return 0.0;
}

private static double blockOverlayPlacementOffsetY(String placement, double padding) {
	if (placement.startsWith("TOP_"))
		return -padding;
	if (placement.startsWith("BOTTOM_"))
		return padding;
	return 0.0;
}

private static float blockOverlayTextFitScale(float requestedScale, int width, int height) {
	float maximumScale = Math.min(0.95f / Math.max(1, width), 0.95f / Math.max(1, height));
	return Math.copySign(Math.min(0.025f * Math.abs(requestedScale), maximumScale), requestedScale);
}