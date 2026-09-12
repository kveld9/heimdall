"""Base collector interface for WatchCat telemetry."""

import abc
from typing import Any, Dict


class BaseCollector(abc.ABC):
    """Abstract base class ensuring consistent collector structure and lifecycle."""

    @abc.abstractmethod
    def collect(self) -> Dict[str, Any]:
        """Collect and return metrics snapshot as a JSON-serializable dictionary."""
        raise NotImplementedError
