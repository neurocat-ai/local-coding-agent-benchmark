using GuardErp.Api.Shifts;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<IShiftRepository, InMemoryShiftRepository>();
builder.Services.AddSingleton<ShiftSchedulingService>();

var app = builder.Build();

app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.MapGet("/api/shifts", async (IShiftRepository repository) =>
    Results.Ok(await repository.ListAsync()));

app.MapPost("/api/shifts", async (
    CreateShiftRequest request,
    ShiftSchedulingService service,
    CancellationToken cancellationToken) =>
{
    var result = await service.ScheduleAsync(request, cancellationToken);
    return result.IsSuccess
        ? Results.Created($"/api/shifts/{result.Shift!.Id}", result.Shift)
        : Results.BadRequest(new { error = result.Error });
});

app.Run();

public partial class Program;
