using GuardErp.Api.Payroll;

namespace GuardErp.Tests;

public sealed class ShiftPayCalculatorTests
{
    private readonly ShiftPayCalculator _calculator = new();

    [Fact]
    public void Calculates_regular_shift_pay()
    {
        var startsAt = DateTimeOffset.Parse("2026-09-04T08:00:00+00:00");

        var pay = _calculator.Calculate(startsAt, startsAt.AddHours(8), 100m);

        Assert.Equal(800m, pay);
    }

    [Fact]
    public void Calculates_regular_overnight_shift_pay()
    {
        var startsAt = DateTimeOffset.Parse("2026-09-04T22:00:00+00:00");

        var pay = _calculator.Calculate(startsAt, startsAt.AddHours(8), 100m);

        Assert.Equal(800m, pay);
    }

    [Fact]
    public void Rejects_negative_hourly_rate()
    {
        var startsAt = DateTimeOffset.Parse("2026-09-04T08:00:00+00:00");

        Assert.Throws<ArgumentOutOfRangeException>(() =>
            _calculator.Calculate(startsAt, startsAt.AddHours(8), -1m));
    }
}
