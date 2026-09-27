namespace GuardErp.Api.Shifts;

public sealed record Shift(
    Guid Id,
    Guid EmployeeId,
    Guid SiteId,
    DateTimeOffset StartsAt,
    DateTimeOffset EndsAt);

public sealed record CreateShiftRequest(
    Guid EmployeeId,
    Guid SiteId,
    DateTimeOffset StartsAt,
    DateTimeOffset EndsAt);

public sealed record ScheduleShiftResult(bool IsSuccess, Shift? Shift, string? Error)
{
    public static ScheduleShiftResult Success(Shift shift) => new(true, shift, null);
    public static ScheduleShiftResult Failure(string error) => new(false, null, error);
}
