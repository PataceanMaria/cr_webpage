# Assets Setup Instructions

## Required Images

To use the custom images in the game, please add the following images to the `assets/images/` directory:

1. **background.png** - The background image of the modern building with sky
2. **bowling_ball.png** - The bowling ball image with black and yellow stripes

## Image Requirements

- **background.png**: Should be a wide image that can be used as a scrolling background. Recommended dimensions: at least 1920x1080 pixels or wider for better scrolling effect.
- **bowling_ball.png**: Should be a square image of the bowling ball with transparent background. Recommended dimensions: 200x200 pixels or larger.

## Adding Images

1. Place your `background.png` and `bowling_ball.png` files in the `assets/images/` directory
2. The game will automatically use these images when available
3. If the images are not found, the game will use fallback graphics:
   - Background: Blue to green gradient (sky to grass)
   - Bowling ball: Custom painted black circle with yellow stripes pattern

## Running the Game

After adding the images, run:
```bash
flutter pub get
flutter run
```

The game will work with or without the images, but will look much better with your custom assets!

