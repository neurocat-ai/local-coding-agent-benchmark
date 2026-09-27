namespace GuardErp.Api.Shifts;

public interface IShiftRepository
{
    Task<IReadOnlyList<Shift>> ListAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Shift>> ListForEmployeeAsync(Guid employeeId, CancellationToken cancellationToken = default);
    Task AddAsync(Shift shift, CancellationToken cancellationToken = default);
}
