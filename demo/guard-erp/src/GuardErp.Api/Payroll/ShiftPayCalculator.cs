namespace GuardErp.Api.Payroll;

public sealed class ShiftPayCalculator
{
    public decimal Calculate(
        DateTimeOffset startsAt,
        DateTimeOffset endsAt,
        decimal hourlyRate)
    {
        if (startsAt >= endsAt)
        {
            throw new ArgumentException("Shift start must be before shift end.", nameof(endsAt));
        }

        if (hourlyRate < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(hourlyRate), "Hourly rate cannot be negative.");
        }

        var hours = (decimal)(endsAt - startsAt).TotalHours;

        // ERP-003: the current implementation does not apply an overtime rate.
        return decimal.Round(hours * hourlyRate, 2, MidpointRounding.AwayFromZero);
    }
}
