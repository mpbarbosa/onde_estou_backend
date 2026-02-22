# API Documentation

Base URL (production): `https://b2inkriw8k.execute-api.us-east-1.amazonaws.com`

---

## POST /api/geocode/reverse

Converts a latitude/longitude pair to a postal address using AWS Location Service (Esri, optimised for Brazil).

### Request

**Content-Type**: `application/json`

```json
{
  "latitude": -23.550520,
  "longitude": -46.633309
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `latitude` | number | ✓ | Decimal degrees, WGS 84 |
| `longitude` | number | ✓ | Decimal degrees, WGS 84 |

> **Note**: AWS Location Service expects coordinates as `[longitude, latitude]`. The Lambda handler performs this reversal automatically.

### Response — 200 OK

```json
{
  "provider": "aws-location-service",
  "coordinates": {
    "latitude": -23.550520,
    "longitude": -46.633309
  },
  "address": {
    "label": "Av. Paulista, 1578, São Paulo, SP",
    "street": "Avenida Paulista",
    "addressNumber": "1578",
    "neighborhood": "Bela Vista",
    "municipality": "São Paulo",
    "subRegion": "Centro",
    "region": "São Paulo",
    "country": "BRA",
    "postalCode": "01310-200",
    "interpolated": false
  },
  "geometry": {
    "Point": [-46.633309, -23.550520]
  }
}
```

| Field | Type | Description |
|---|---|---|
| `provider` | string | Always `"aws-location-service"` |
| `coordinates.latitude` | number | Input latitude echoed back |
| `coordinates.longitude` | number | Input longitude echoed back |
| `address.label` | string | Full formatted address string |
| `address.subRegion` | string | District or sub-region (if available) |
| `address.interpolated` | boolean | `true` if address was interpolated (not exact match) |
| `geometry.Point` | [number, number] | Matched coordinates as `[longitude, latitude]` |

### Error Responses

| Status | Cause |
|---|---|
| `400` | Missing or non-numeric `latitude`/`longitude` |
| `404` | No address found for the given coordinates |
| `500` | AWS Location Service error (`ResourceNotFoundException`, `AccessDeniedException`) |

---

## GET /api/map/credentials

Returns the MapLibre GL JS map configuration (style URL, region, and default viewport).

### Response — 200 OK

```json
{
  "mapName": "onde-estou-map",
  "region": "us-east-1",
  "style": "VectorEsriNavigation",
  "mapLibre": {
    "version": "4.0.0",
    "styleUrl": "https://maps.geo.us-east-1.amazonaws.com/maps/v0/maps/onde-estou-map/style-descriptor"
  },
  "defaults": {
    "center": [-46.633309, -23.550520],
    "zoom": 12
  }
}
```

---

## Scripts Reference

### `src/scripts/setup-aws-infrastructure.sh`

Provisions all AWS resources (run once per environment).

```bash
./src/scripts/setup-aws-infrastructure.sh
# Override region:
AWS_REGION=sa-east-1 ./src/scripts/setup-aws-infrastructure.sh
```

**Creates**: Location Map, Place Index, IAM role & policy.  
**Output**: writes `src/aws-config.json`.

### `src/scripts/deploy-backend.sh`

Packages and deploys Lambda functions and API Gateway (idempotent).

```bash
./src/scripts/deploy-backend.sh
# Override CORS origin:
ALLOWED_ORIGIN=http://localhost:3000 ./src/scripts/deploy-backend.sh
```

**Environment variables set on Lambdas**:

| Variable | Lambda | Default |
|---|---|---|
| `AWS_REGION` | both | `us-east-1` |
| `PLACE_INDEX_NAME` | geocode-reverse | `onde-estou-place-index` |
| `MAP_NAME` | map-credentials | `onde-estou-map` |
| `ALLOWED_ORIGIN` | both | `https://www.mpbarbosa.com` |
