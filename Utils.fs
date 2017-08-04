namespace Utils

module Env =
    let varRequired key = 
        let value = System.Environment.GetEnvironmentVariable key

        if isNull value then failwithf "Environment Variable \"%s\" was not found." key

        value

    let varDefault key defaultValue =
        let value = System.Environment.GetEnvironmentVariable key

        if isNull value then defaultValue else value