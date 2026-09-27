using GuardErp.Api.Reports;
using GuardErp.Api.Security;

namespace GuardErp.Tests;

public sealed class PayrollReportServiceTests
{
    private readonly PayrollReportAuthorization _authorization = new();

    [Theory]
    [InlineData(UserRole.Administrator)]
    [InlineData(UserRole.PayrollManager)]
    public void Existing_privileged_roles_can_read_and_modify(UserRole role)
    {
        var service = new PayrollReportService(_authorization);
        var replacement = new PayrollReport("2026-10", 12500m);

        service.Replace(role, replacement);

        Assert.Equal(replacement, service.Read(role));
    }

    [Fact]
    public void Supervisor_cannot_read_or_modify()
    {
        var service = new PayrollReportService(_authorization);

        Assert.Throws<UnauthorizedAccessException>(() => service.Read(UserRole.Supervisor));
        Assert.Throws<UnauthorizedAccessException>(() =>
            service.Replace(UserRole.Supervisor, new PayrollReport("2026-10", 12500m)));
    }
}
