# BRNetwork

- BRNetwork 提供極輕量的網路層封裝

## 功能特色

### 簡單使用 BRNetwork 包裝自己的客戶端 Server 物件

``` swift
import BRFoundation
import BRNetwork
import Foundation


final class ReqResService {
    
    static let shared = ReqResService()
    private let network = BRNetwork()

    var host = URL(string: "https://reqres.in/api")!

    
    private init() {}
    
    
    func request(form request: BRRequest) -> BRRequest {
        request
            .header("x-api-key", "reqres-free-v1")
    }

    
    func fetchAPI<T: Decodable>(_ request: BRRequest, as type: T.Type) async throws -> (BRResponse, T) {
        let response = try await network.sendRequest(request, options: BRRequestOptions(
            onFailure: { error, response in
                BRLog.net.error("[Network] response error:\(error.localizedDescription)")
                BRLog.net.error("[Network] response:\(response)")
            },
            enrichMessage: { statusCode, data in
                try? ErrorResponse.fromJSONData(data).error
            }
        ))
        let data = try JSONDecoder().decode(T.self, from: response.data)
        return (response, data)
    }
    
    
}
```

### 簡單區分錯誤來源

- client
    - App 端錯誤，例如 request 構造錯誤、JSON encode 問題
- server
    - 收到 Response，但 statusCode 非 2xx，並且附帶錯誤資料
- network
    - 無法建立連線，或無法獲得任何回應（URLError 轉出）
        
### 簡單除錯

- BRRequest、BRResponse 提供漂亮的格式印出，可以在 Log 直接展示完整封包資訊
- BRNetwork 的 sendRequest 功能
    - 發生錯誤時，可以從 onFailure closure 取得 error、BRResponse 分辨失敗的 API
    - 當發生 server 端錯誤時，enrichMessage closure 可以提供錯誤封包解析，並且將訊息放入 BRNetworkError.server 一並觸發 throw
        
### 安全處理

- BRRequest、BRResponse 在 Release 模式下，會自動屏蔽掉可能敏感的資訊
    
## 綁定操作簡化

通用的任務狀態 `BRTaskState` 能將 ViewModel、ViewController 操作大幅減少

### ViewModel

``` swift
import BRFoundation
import Foundation


@MainActor
final class APIViewModel: BRObservableObject {
    
    private let api: ReqResAPIProtocol
    private var task: Task<Void, Never>?
    
    @Published var usersState: BRTaskState<UserListResponse> = .idle
    
    init(api: ReqResAPIProtocol = ReqResAPI()) {
        self.api = api
    }

    
    func fetchUsers() {
        task = br.load(\.usersState) {
            try await self.api.listUsers(page: 0)
        }
    }
    
    
    func cancel() {
        task?.cancel()
    }
    
    
}
```

### ViewController

``` swift
import BRFoundation
import Combine
import UIKit


class ViewController: UIViewController {
    
    private var viewModel = APIViewModel()
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        BRTask.bind(to: viewModel.$usersState, on: self) { users in
            print(users)
        }.store(in: &cancellables)
    }
    
}
```

## 主要元件

### BRNetwork

- 負責網路請求等功能操作

### BRNetworkError

- 封裝網路請求過程的 Error
- 依據錯誤端區分成 client、server、network 等錯誤

### BRRequest

- 封裝網路請求資訊
- 提供 DSL 語法建立
- 提供 Log 打印
- Release 模式下隱藏 url、header 資訊

### BRResponse
- 封裝 Request、Response 等，網路請求的完整資訊
- 提供 Log 打印
