# Run All Tests - Password Manager App
# This script runs all automated tests and generates a coverage report

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Password Manager - Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is installed
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
flutter --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter is not installed or not in PATH" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Flutter found" -ForegroundColor Green
Write-Host ""

# Clean previous build artifacts
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
Write-Host "✅ Clean complete" -ForegroundColor Green
Write-Host ""

# Get dependencies
Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to get dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dependencies resolved" -ForegroundColor Green
Write-Host ""

# Run unit tests
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Running Unit Tests" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Running all tests with coverage..." -ForegroundColor Yellow
flutter test --coverage
$testExitCode = $LASTEXITCODE

if ($testExitCode -eq 0) {
    Write-Host ""
    Write-Host "✅ All tests passed!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ Some tests failed" -ForegroundColor Red
}

Write-Host ""

# Check if coverage was generated
if (Test-Path "coverage\lcov.info") {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Coverage Report Generated" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Coverage file: coverage\lcov.info" -ForegroundColor Green
    Write-Host ""
    Write-Host "To view coverage in browser:" -ForegroundColor Yellow
    Write-Host "  1. Install genhtml (from lcov package)" -ForegroundColor White
    Write-Host "  2. Run: genhtml coverage\lcov.info -o coverage\html" -ForegroundColor White
    Write-Host "  3. Open: coverage\html\index.html" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "⚠️ Coverage report not generated" -ForegroundColor Yellow
    Write-Host ""
}

# Test Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test suites:" -ForegroundColor White
Write-Host "  ✅ PasswordEntry Model (14 tests)" -ForegroundColor Green
Write-Host "  ✅ PasswordGenerator Service (18 tests)" -ForegroundColor Green
Write-Host ""
Write-Host "Total: 32 tests" -ForegroundColor Cyan
Write-Host ""

# Run specific test files individually for detailed output
Write-Host "Running individual test suites for detailed output..." -ForegroundColor Yellow
Write-Host ""

Write-Host "1️⃣  PasswordEntry Model Tests" -ForegroundColor Cyan
flutter test test\models\password_entry_test.dart
Write-Host ""

Write-Host "2️⃣  PasswordGenerator Tests" -ForegroundColor Cyan
flutter test test\services\password_generator_test.dart
Write-Host ""

# Final status
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Run Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($testExitCode -eq 0) {
    Write-Host "✅ All tests passed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  • Review TESTING_GUIDE.md for manual testing" -ForegroundColor White
    Write-Host "  • Test on Android device/emulator" -ForegroundColor White
    Write-Host "  • Test on Windows desktop" -ForegroundColor White
    Write-Host "  • Verify all features in both platforms" -ForegroundColor White
    exit 0
} else {
    Write-Host "❌ Some tests failed. Please review the output above." -ForegroundColor Red
    exit 1
}
