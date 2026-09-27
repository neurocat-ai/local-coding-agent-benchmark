using GuardErp.Api.Shifts;

namespace GuardErp.Tests;

public sealed class ShiftSchedulingServiceTests
{
    [Fact]
    public async Task Rejects_shift_with_invalid_time_range()
    {
        var service = new ShiftSchedulingService(new InMemoryShiftRepository());
        var now = DateTimeOffset.Parse("2026-09-04T08:00:00+00:00");

        var result = await service.ScheduleAsync(new CreateShiftRequest(
            Guid.NewGuid(), Guid.NewGuid(), now.AddHours(8), now));

        Assert.False(result.IsSuccess);
        Assert.Equal("Shift start must be before shift end.", result.Error);
    }

    [Fact]
    public async Task Accepts_valid_shift()
    {
        var repository = new InMemoryShiftRepository();
        var service = new ShiftSchedulingService(repository);
        var now = DateTimeOffset.Parse("2026-09-04T08:00:00+00:00");

        var result = await service.ScheduleAsync(new CreateShiftRequest(
            Guid.NewGuid(), Guid.NewGuid(), now, now.AddHours(8)));

        Assert.True(result.IsSuccess);
        Assert.Single(await repository.ListAsync());
    }
}
