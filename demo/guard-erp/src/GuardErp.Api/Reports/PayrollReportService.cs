using GuardErp.Api.Security;

namespace GuardErp.Api.Reports;

public sealed class PayrollReportService(PayrollReportAuthorization authorization)
{
    private PayrollReport _report = new("2026-09", 0m);

    public PayrollReport Read(UserRole role)
    {
        if (!authorization.CanRead(role))
        {
            throw new UnauthorizedAccessException("The role cannot read payroll reports.");
        }

        return _report;
    }

    public void Replace(UserRole role, PayrollReport report)
    {
        if (!authorization.CanModify(role))
        {
            throw new UnauthorizedAccessException("The role cannot modify payroll reports.");
        }

        _report = report;
    }
}
