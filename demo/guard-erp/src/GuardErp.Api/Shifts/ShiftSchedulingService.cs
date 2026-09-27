namespace GuardErp.Api.Shifts;

public sealed class ShiftSchedulingService(IShiftRepository repository)
{
    public async Task<ScheduleShiftResult> ScheduleAsync(
        CreateShiftRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.StartsAt >= request.EndsAt)
        {
            return ScheduleShiftResult.Failure("Shift start must be before shift end.");
        }

        // ERP-001 intentionally starts without overlap validation.
        var shift = new Shift(
            Guid.NewGuid(),
            request.EmployeeId,
            request.SiteId,
            request.StartsAt,
            request.EndsAt);

        await repository.AddAsync(shift, cancellationToken);
        return ScheduleShiftResult.Success(shift);
    }
}
