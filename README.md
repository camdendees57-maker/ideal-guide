# Gorilla Locomotion Lab

A 3-D OpenXR test game for experimenting with Gorilla Tag-style arm locomotion.

Included:
- OpenXR initialization
- Left and right tracked controllers
- Physics-based player body
- Grip/trigger surface grabbing
- Hand velocity converted into opposite body velocity
- A small obstacle course with walls, blocks, and platforms
- Android APK export through GitHub Actions

This is deliberately a prototype so the locomotion can be tested before adding multiplayer, cosmetics, maps, or other systems.

## Controls

On an OpenXR-compatible headset:
1. Hold grip or trigger near a solid surface.
2. Push or pull your hand against the surface.
3. Your body moves opposite the hand motion.
4. Release to stop applying propulsion.

## GitHub build

Pushes and manual workflow runs build an Android APK. The APK is uploaded as a GitHub Actions artifact.

GitHub Actions workflows live in the .github/workflows directory and can preserve build outputs as workflow artifacts.
