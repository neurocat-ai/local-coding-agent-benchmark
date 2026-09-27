namespace GuardErp.Api.Shifts;

public sealed class InMemoryShiftRepository : IShiftRepository
{
    private readonly List<Shift> _shifts = [];
    private readonly object _gate = new();

    public Task<IReadOnlyList<Shift>> ListAsync(CancellationToken cancellationToken = default)
    {
        lock (_gate)
        {
            return Task.FromResult<IReadOnlyList<Shift>>(_shifts.ToArray());
        }
    }

    public Task<IReadOnlyList<Shift>> ListForEmployeeAsync(Guid employeeId, CancellationToken cancellationToken = default)
    {
        lock (_gate)
        {
            return Task.FromResult<IReadOnlyList<Shift>>(
                _shifts.Where(shift => shift.EmployeeId == employeeId).ToArray());
        }
    }

    public Task AddAsync(Shift shift, CancellationToken cancellationToken = default)
    {
        lock (_gate)
        {
            _shifts.Add(shift);
        }

        return Task.CompletedTask;
    }
}
