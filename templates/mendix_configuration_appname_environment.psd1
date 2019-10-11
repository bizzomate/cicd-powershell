@{
    #Environment to build and deploy for
    Environment     = @{
        AppName     = '<app-name>'
        Environment = '<Test/Accp/Prod>'
        BranchName  = '<trunk/branch-name>'
    }
    
    # Scheduled events that are set active (Name: Value)
    ScheduledEvents = @{
        # 'Module.ScheduledEventname' = "Enabled"
        # 'Module.ScheduledEventname2' = "Disabled"
    }
    
    # Constants to set before start
    # Only contstants to set different from the default could be set.
    Constants = @{
        # 'Module.ConstantName' = "Value"
        # 'Module2.ConstantName' = "Value2"
    }

    # Custom runtime settings (Name & Value)
    CustomSettings  = @{
        # 'PersistentSessions' = "false"
    }
}