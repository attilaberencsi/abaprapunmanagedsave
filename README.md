# Managed RAP Scenario with Unmanaged Save

About Managed implementation type with unmanaged or additional save:

- The implementation types with unmanaged save or additional save represent variants of the managed scenario
- Whereas in the managed implementation type the interaction phase and the save sequence are completely taken over by the RAP framework, in these two variants you can manipulate the persistence of the data
- In the variant with unmanaged save, you assume the entire responsibility for persistence
- In the variant with additional save you can add additional logic to the persistence managed by the framework
- The interaction phase is still managed by the RAP framework in both variants

![kép](https://github.com/attilaberencsi/zrapunmanagedsave/assets/20442467/4d65fc7c-e9d9-41e9-ae9a-64a1d4943811)

Reference: https://www.sap-press.com/abap-restful-application-programming-model_5647/
