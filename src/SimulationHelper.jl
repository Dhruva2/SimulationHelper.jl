"""

- You can record an interaction or an entity
 Requirements

 interactions have a functor:

 int(time, to_whom, args, kwargs)

"""

module SimulationHelper

import Base.getindex, Base.show




include("SimpleInteraction.jl")
export RecordedUpdate, SimpleRecorder, CompositeRecord, compose_updates


end
