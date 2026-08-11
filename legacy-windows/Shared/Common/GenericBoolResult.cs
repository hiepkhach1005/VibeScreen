namespace ColorControl.Shared.Common;

public class GenericBoolResult : GenericResult<bool>
{
    public static GenericBoolResult Success => new() { HasResult = true, Result = true };
    public static new GenericBoolResult FromError(string error)
    {
        return new GenericBoolResult
        {
            HasResult = false,
            ErrorMessages = [error]
        };
    }

    public override void AddError(string error)
    {
        base.AddError(error);
        Result = false;
    }
}

public class GenericResult<T>
{
    public bool HasResult { get; set; }
    public List<string> ErrorMessages { get; protected set; } = [];
    public T Result { get; set; }

    public static GenericResult<T> FromError(string error)
    {
        return new GenericResult<T>
        {
            HasResult = false,
            ErrorMessages = [error]
        };
    }

    public static GenericResult<T> FromSuccess(T result)
    {
        return new GenericResult<T>
        {
            HasResult = true,
            Result = result
        };
    }

    public virtual void AddError(string error)
    {
        ErrorMessages.Add(error);
    }
}